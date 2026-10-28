#!/bin/bash
# =============================================================
#  Business Ledger Build Script
#  Usage: ./build.sh  (run from project root)
#  Supports: APK, AAB, IPA — dev and prod, debug/profile/release
#
#  Flavors are Dart-only: the entry point picks them
#  (-t lib/main_dev.dart / lib/main_prod.dart); there are no
#  Gradle or Xcode flavors.
#
#  For prod + release builds an interactive pre-flight checklist
#  runs once (version, signing, code checks, Supabase backend,
#  git tag). Several production artifacts can then be built in
#  one session without repeating it.
# =============================================================

set -e

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────
print_line() { echo -e "  ${BOLD}${CYAN}────────────────────────────────────────────${NC}"; }

# Section header used by the production checklist
step_header() {
  echo ""
  print_line
  echo -e "  ${BOLD}${YELLOW}$1${NC}"
  print_line
}

# Print a message and exit (non-zero)
abort() {
  echo -e "\n  ${RED}✖ $1${NC}\n"
  exit 1
}

# Yes/No prompt. Returns 0 for yes, 1 for no. Always call in a condition.
ask_yes_no() {
  local prompt="$1" answer
  while true; do
    echo -ne "  ${YELLOW}${prompt} (y/n): ${NC}"
    read -r answer
    case "$answer" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      *)   echo -e "  ${DIM}Please answer y or n.${NC}" ;;
    esac
  done
}

# Require an explicit "y" to continue — keeps asking until confirmed.
confirm_required() {
  local prompt="$1" answer
  while true; do
    echo -ne "  ${YELLOW}${prompt} (y): ${NC}"
    read -r answer
    case "$answer" in
      y|Y) return 0 ;;
      *)   echo -e "  ${DIM}Type 'y' to confirm and continue.${NC}" ;;
    esac
  done
}

# Run a command, report pass/fail, return its exit code.
run_check() {
  local label="$1"; shift
  echo -e "  ${DIM}\$ $*${NC}"
  set +e
  "$@"
  local code=$?
  set -e
  if [[ $code -eq 0 ]]; then
    echo -e "  ${GREEN}✔ ${label} passed.${NC}"
  else
    echo -e "  ${RED}✖ ${label} failed (exit code ${code}).${NC}"
  fi
  return $code
}

# ── Version helpers ───────────────────────────────────────────
# Full "0.1.0+1" from the "version: 0.1.0+1" line in pubspec.yaml
read_pubspec_full_version() {
  local line full
  line=$(grep -m1 '^version:' pubspec.yaml 2>/dev/null || true)
  full="${line#version:}"
  full="${full//[[:space:]]/}"
  echo "$full"
}

# "0.1.0"
read_pubspec_version() {
  local full
  full=$(read_pubspec_full_version)
  echo "${full%%+*}"
}

# "1" (the build number), empty when there is none
read_pubspec_build_number() {
  local full
  full=$(read_pubspec_full_version)
  [[ "$full" == *+* ]] && echo "${full##*+}" || echo ""
}

# ── Firebase / Crashlytics ────────────────────────────────────
# Firebase CLI calls always use the project's personal account.
FIREBASE_ACCOUNT="sreeragk136@gmail.com"
FIREBASE_OPTIONS="lib/app/firebase_options_prod.dart"
DEBUG_INFO_DIR="build/debuginfo"

# Firebase app id for "android" or "ios", read from the prod options.
firebase_app_id() {
  grep -o "1:[0-9]*:$1:[0-9a-f]*" "$FIREBASE_OPTIONS" 2>/dev/null | head -1
}

# Obfuscated builds need their Dart symbols in Crashlytics, or crash
# reports show unreadable stack traces. Offered after each prod build.
offer_symbol_upload() {
  local platform="$1" app_id
  app_id=$(firebase_app_id "$platform")
  if [[ -z "$app_id" ]]; then
    echo -e "  ${YELLOW}⚠ No ${platform} app id in ${FIREBASE_OPTIONS} — upload Dart symbols by hand.${NC}"
    return 0
  fi
  if ! command -v firebase &>/dev/null; then
    echo -e "  ${YELLOW}⚠ Firebase CLI not installed — Dart symbols in ${DEBUG_INFO_DIR} were not uploaded.${NC}"
    return 0
  fi
  if ask_yes_no "Upload Dart symbols to Crashlytics (${platform})?"; then
    set +e
    firebase crashlytics:symbols:upload --app="$app_id" "$DEBUG_INFO_DIR" \
      --account "$FIREBASE_ACCOUNT"
    local code=$?
    set -e
    if [[ $code -eq 0 ]]; then
      echo -e "  ${GREEN}✔ Dart symbols uploaded.${NC}"
    else
      echo -e "  ${YELLOW}⚠ Symbol upload failed (exit code ${code}). Retry later with:${NC}"
      echo -e "  ${DIM}firebase crashlytics:symbols:upload --app=${app_id} ${DEBUG_INFO_DIR} --account ${FIREBASE_ACCOUNT}${NC}"
    fi
  fi
  return 0
}

# ── Git tag ───────────────────────────────────────────────────
# Create the tag v<version>+<build>, and push it only on a second yes.
create_git_tag() {
  local full tag
  full=$(read_pubspec_full_version)

  if [[ -z "$full" ]]; then
    echo -e "  ${YELLOW}⚠ Could not read version from pubspec.yaml — skipping git tag.${NC}"
    GIT_TAG_STATUS="✓ Git tag skipped (version not found)"
    return 0
  fi

  tag="v${full}"
  echo -e "  ${DIM}Detected version:${NC} ${BOLD}${full}${NC}"

  if ! ask_yes_no "Create Git tag ${tag}?"; then
    GIT_TAG_STATUS="✓ Git tag skipped"
    return 0
  fi

  if git rev-parse "$tag" >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠ Tag ${tag} already exists — skipping creation.${NC}"
    GIT_TAG_STATUS="✓ Git tag ${tag} already existed"
    return 0
  fi

  if ! git tag "$tag" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ Could not create tag ${tag}.${NC}"
    GIT_TAG_STATUS="✓ Git tag ${tag} creation failed"
    return 0
  fi
  echo -e "  ${GREEN}✔ Created tag ${tag}.${NC}"
  GIT_TAG_STATUS="✓ Git tag ${tag} created (not pushed)"

  echo -e "  ${DIM}origin: $(git remote get-url origin 2>/dev/null || echo '<none>')${NC}"
  if ask_yes_no "Push ${tag} to origin?"; then
    if git push origin "$tag" 2>/dev/null; then
      echo -e "  ${GREEN}✔ Pushed ${tag} to origin.${NC}"
      GIT_TAG_STATUS="✓ Git tag ${tag} created & pushed"
    else
      echo -e "  ${YELLOW}⚠ Could not push ${tag} to origin.${NC}"
      GIT_TAG_STATUS="✓ Git tag ${tag} created (push failed)"
    fi
  fi
}

# ── Production checklist (runs ONCE per session) ───────────────
run_production_checklist() {
  echo ""
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║     Production Release Checklist  🔒        ║${NC}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════╝${NC}"

  # Step 1 — Version
  step_header "Step 1 — Version & Build Number"
  local pubspec_full pubspec_ver pubspec_build
  pubspec_full=$(read_pubspec_full_version)
  pubspec_ver=$(read_pubspec_version)
  pubspec_build=$(read_pubspec_build_number)
  if [[ -n "$pubspec_full" ]]; then
    echo -e "  ${DIM}pubspec.yaml →${NC} ${BOLD}${pubspec_full}${NC}"
    echo -e "  ${DIM}Version     :${NC} ${BOLD}${pubspec_ver}${NC}"
    echo -e "  ${DIM}Build number:${NC} ${BOLD}${pubspec_build:-<none>}${NC}"
  else
    echo -e "  ${YELLOW}⚠ Could not read version from pubspec.yaml.${NC}"
  fi
  echo -e "  ${DIM}The stores reject a build number they have seen before.${NC}"
  confirm_required "Have you updated the version and build number in pubspec.yaml?"
  VERSION_STATUS="✓ Version & build number verified${pubspec_full:+ (${pubspec_full})}"

  # Step 2 — Android release signing (android/key.properties, not in git)
  step_header "Step 2 — Android Release Signing"
  if [[ -f "android/key.properties" ]]; then
    echo -e "  ${GREEN}✔ android/key.properties found — release builds use the upload key.${NC}"
    SIGNING_STATUS="✓ Release signing key configured"
  else
    echo -e "  ${YELLOW}⚠ android/key.properties is missing: Android release builds are signed${NC}"
    echo -e "  ${YELLOW}  with the debug key. Fine for testing; Google Play will reject them.${NC}"
    echo -e "  ${DIM}  key.properties: storeFile=<path from android/app>, storePassword, keyAlias, keyPassword${NC}"
    if ! ask_yes_no "Continue with debug signing?"; then
      abort "Release signing not configured. Aborting production build."
    fi
    SIGNING_STATUS="⚠ Android signed with the debug key (not for Play)"
  fi

  # Step 3 — Working tree
  step_header "Step 3 — Uncommitted Changes"
  local changes
  changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d '[:space:]')
  if [[ "$changes" -eq 0 ]]; then
    echo -e "  ${GREEN}✔ Working tree is clean.${NC}"
    TREE_STATUS="✓ Built from committed code"
  else
    echo -e "  ${YELLOW}⚠ ${changes} uncommitted change(s): this build won't match any commit.${NC}"
    if ask_yes_no "Show them?"; then
      git status --short
    fi
    if ! ask_yes_no "Build anyway?"; then
      abort "Commit your changes first. Aborting production build."
    fi
    TREE_STATUS="⚠ Built with ${changes} uncommitted change(s)"
  fi

  # Step 4 — Code checks (CLAUDE.md: format, analyze, test)
  step_header "Step 4 — Format, Analyze, Test"
  if ask_yes_no "Run dart format check, flutter analyze and flutter test now?"; then
    run_check "Format" ${DART} format --output=none --set-exit-if-changed lib test \
      || abort "Unformatted code. Run: dart format lib test"
    run_check "Analyze" ${FLUTTER} analyze \
      || abort "flutter analyze reported issues."
    run_check "Tests" ${FLUTTER} test \
      || abort "Tests failed."
    CHECKS_STATUS="✓ Format, analyze and tests passed"
  else
    confirm_required "Have format, analyze and tests passed on this code?"
    CHECKS_STATUS="✓ Format, analyze and tests confirmed"
  fi

  # Step 5 — Supabase backend the app expects
  step_header "Step 5 — Supabase Backend"
  if command -v npx &>/dev/null && ask_yes_no "Show Supabase migrations, local vs remote (read-only)?"; then
    set +e
    npx supabase migration list
    set -e
    echo -e "  ${DIM}Every local migration needs a Remote entry; apply missing ones with: npx supabase db push${NC}"
  fi
  confirm_required "Are all migrations applied to the live database?"
  confirm_required "Is the scan-receipt Edge Function deployed (and ANTHROPIC_API_KEY set)?"
  BACKEND_STATUS="✓ Migrations and Edge Function verified"

  # Step 6 — Git Tag
  step_header "Step 6 — Git Tag"
  create_git_tag

  # Step 7 — Final Review
  run_final_review
}

run_final_review() {
  step_header "Step 7 — Final Review"
  local status
  for status in "$VERSION_STATUS" "$SIGNING_STATUS" "$TREE_STATUS" \
    "$CHECKS_STATUS" "$BACKEND_STATUS" "$GIT_TAG_STATUS"; do
    if [[ "$status" == ⚠* ]]; then
      echo -e "  ${YELLOW}${status}${NC}"
    else
      echo -e "  ${GREEN}${status}${NC}"
    fi
  done
  echo -e "  ${DIM}• Release builds are obfuscated; Dart symbols go to ${DEBUG_INFO_DIR}.${NC}"
  echo ""
  if ! ask_yes_no "Start production build?"; then
    abort "Production build cancelled by user."
  fi
}

# ── Build helpers (shared by first build + 'build next' loop) ──
# Set BUILD_TYPE / BUILD_CMD / OUTPUT_PATH / BUILD_PLATFORM for a build
# choice (1=APK 2=AAB 3=IPA).
set_build_vars() {
  local choice="$1" extra=""

  # Production release builds are obfuscated; the symbols stay local
  # (and can be uploaded to Crashlytics after the build).
  if [[ "$IS_PROD_RELEASE" == "true" ]]; then
    extra=" --obfuscate --split-debug-info=${DEBUG_INFO_DIR}"
  fi
  if [[ -n "$SEL_DEFINES" ]]; then
    extra="${extra} ${SEL_DEFINES}"
  fi

  case "$choice" in
    1)
      BUILD_TYPE="APK"
      BUILD_PLATFORM="android"
      BUILD_CMD="${FLUTTER} build apk -t ${SEL_MAIN} --${SEL_MODE}${extra}"
      OUTPUT_PATH="build/app/outputs/flutter-apk/app-${SEL_MODE}.apk"
      ;;
    2)
      BUILD_TYPE="AAB"
      BUILD_PLATFORM="android"
      BUILD_CMD="${FLUTTER} build appbundle -t ${SEL_MAIN} --${SEL_MODE}${extra}"
      OUTPUT_PATH="build/app/outputs/bundle/${SEL_MODE}/app-${SEL_MODE}.aab"
      ;;
    3)
      if [[ "$SEL_MODE" == "debug" ]]; then
        echo -e "\n  ${RED}❌ An IPA needs profile or release mode — pick another configuration.${NC}"
        return 1
      fi
      BUILD_TYPE="IPA"
      BUILD_PLATFORM="ios"
      BUILD_CMD="${FLUTTER} build ipa -t ${SEL_MAIN} --${SEL_MODE}${extra}"
      OUTPUT_PATH="build/ios/ipa/"
      ;;
    *)
      echo -e "\n  ${RED}❌ Invalid build type.${NC}"
      return 1
      ;;
  esac
  BUILD_CHOICE="$choice"
  return 0
}

print_summary() {
  echo ""
  print_line
  echo -e "  ${BOLD}Build Summary${NC}"
  print_line
  echo -e "  ${DIM}Config  :${NC} ${SEL_NAME}"
  echo -e "  ${DIM}Main    :${NC} ${SEL_MAIN}"
  echo -e "  ${DIM}Mode    :${NC} ${SEL_MODE}"
  echo -e "  ${DIM}Type    :${NC} ${BUILD_TYPE}"
  echo -e "  ${DIM}Command :${NC} ${BOLD}${BUILD_CMD}${NC}"
  echo -e "  ${DIM}Output  :${NC} ${OUTPUT_PATH}"
  print_line
}

run_build_and_report() {
  echo ""
  echo -e "  ${BOLD}${GREEN}🔨 Building ${BUILD_TYPE} — ${SEL_NAME}...${NC}"
  echo ""

  local start_time end_time duration mins secs finder_dir

  start_time=$(date +%s)

  # Run the build (disable set -e temporarily to capture exit code)
  set +e
  eval "$BUILD_CMD"
  BUILD_EXIT_CODE=$?
  set -e

  end_time=$(date +%s)
  duration=$((end_time - start_time))
  mins=$((duration / 60))
  secs=$((duration % 60))

  echo ""
  print_line
  if [[ $BUILD_EXIT_CODE -eq 0 ]]; then
    echo -e "  ${BOLD}${GREEN}✅ Build Successful!${NC}"
    echo -e "  ⏱  Time   : ${mins}m ${secs}s"
    echo -e "  📦 Output : ${BOLD}${OUTPUT_PATH}${NC}"
    echo ""
    if [[ "$IS_PROD_RELEASE" == "true" ]]; then
      offer_symbol_upload "$BUILD_PLATFORM"
    fi
    # Open in Finder (macOS only)
    if command -v open &>/dev/null; then
      if [[ "$BUILD_CHOICE" -eq 3 ]]; then
        finder_dir="$OUTPUT_PATH"
      else
        finder_dir=$(dirname "$OUTPUT_PATH")
      fi
      if ask_yes_no "Open output in Finder?"; then
        open "$finder_dir" 2>/dev/null || echo -e "  ${DIM}(Folder not found — the build may have used a different path)${NC}"
      fi
    fi
  else
    echo -e "  ${BOLD}${RED}❌ Build Failed  (exit code: ${BUILD_EXIT_CODE})${NC}"
    echo -e "  ⏱  Time : ${mins}m ${secs}s"
  fi
  print_line
  echo ""
}

# Build one artifact end to end (summary → confirm → build → report).
# Always returns 0 so a failed or cancelled build never breaks the
# 'build next' loop.
build_artifact() {
  local choice="$1"

  if ! set_build_vars "$choice"; then
    echo ""
    return 0
  fi

  echo -e "  ${GREEN}✔ Type    :${NC} ${BOLD}${BUILD_TYPE}${NC}"
  print_summary

  echo ""
  if ! ask_yes_no "⚡ Start build?"; then
    echo -e "\n  ${RED}✖ Build cancelled.${NC}\n"
    return 0
  fi

  run_build_and_report
  return 0
}

# 'Build next' menu shown after each production artifact (no checklist re-run).
next_build_menu() {
  echo ""
  print_line
  echo -e "  ${BOLD}${YELLOW}What would you like to build next?${NC}"
  print_line
  echo -e "    ${BOLD}[1]${NC} APK"
  echo -e "    ${BOLD}[2]${NC} AAB"
  echo -e "    ${BOLD}[3]${NC} IPA"
  echo -e "    ${BOLD}[4]${NC} Exit"
  echo ""
  echo -ne "  ➜ Enter number (1-4): "
  read -r next_choice
}

# Flutter through fvm only when this project pins a version with it.
if [[ -f ".fvmrc" ]] && command -v fvm &>/dev/null; then
  FLUTTER="fvm flutter"
  DART="fvm dart"
else
  FLUTTER="flutter"
  DART="dart"
fi

# ── Guard: must run from project root ─────────────────────────
if [[ ! -f "pubspec.yaml" || ! -f "lib/main_prod.dart" ]]; then
  echo -e "\n  ${RED}❌ Run this script from the project root directory.${NC}"
  echo -e "  ${DIM}Example: cd business_ledger && ./build.sh${NC}\n"
  exit 1
fi

# ── Header ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Business Ledger Build Tool  🚀         ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════╝${NC}"
echo -e "  ${DIM}Flutter: $(${FLUTTER} --version 2>/dev/null | head -1)${NC}"
echo -e "  ${DIM}Version: $(read_pubspec_full_version)${NC}"
echo ""

# ── Configurations (mirror .vscode/launch.json) ───────────────
CONFIG_NAMES=(
  "Dev                        [debug]"
  "Dev (Firebase emulators)   [debug]"
  "Dev                        [profile]"
  "Dev                        [release]"
  "Prod                       [release]"
)
MAIN_FILES=(
  "lib/main_dev.dart"
  "lib/main_dev.dart"
  "lib/main_dev.dart"
  "lib/main_dev.dart"
  "lib/main_prod.dart"
)
MODES=(
  "debug"
  "debug"
  "profile"
  "release"
  "release"
)
DEFINES=(
  ""
  "--dart-define=USE_EMULATOR=true"
  ""
  ""
  ""
)

# ── Step 1: Select Configuration ─────────────────────────────
echo -e "${BOLD}${YELLOW}  Step 1 — Select Configuration:${NC}"
echo ""
for i in "${!CONFIG_NAMES[@]}"; do
  echo -e "    ${BOLD}[$((i+1))]${NC} ${CONFIG_NAMES[$i]}"
done
echo ""
echo -ne "  ➜ Enter number (1-${#CONFIG_NAMES[@]}): "
read -r config_choice

if ! [[ "$config_choice" =~ ^[0-9]+$ ]] || \
   [[ $config_choice -lt 1 ]] || \
   [[ $config_choice -gt ${#CONFIG_NAMES[@]} ]]; then
  echo -e "\n  ${RED}❌ Invalid selection. Exiting.${NC}\n"
  exit 1
fi

IDX=$((config_choice - 1))
SEL_NAME="${CONFIG_NAMES[$IDX]}"
SEL_MAIN="${MAIN_FILES[$IDX]}"
SEL_MODE="${MODES[$IDX]}"
SEL_DEFINES="${DEFINES[$IDX]}"

echo -e "\n  ${GREEN}✔ Config  :${NC} ${BOLD}${SEL_NAME}${NC}"

# ── Step 2: Select Build Type ────────────────────────────────
echo ""
echo -e "${BOLD}${YELLOW}  Step 2 — Select Build Type:${NC}"
echo ""
echo -e "    ${BOLD}[1]${NC} APK  ${DIM}(Android — direct install / sideload)${NC}"
echo -e "    ${BOLD}[2]${NC} AAB  ${DIM}(Android — Play Store upload)${NC}"
echo -e "    ${BOLD}[3]${NC} IPA  ${DIM}(iOS — App Store / TestFlight; needs an Xcode team)${NC}"
echo ""
echo -ne "  ➜ Enter number (1-3): "
read -r build_choice

if ! [[ "$build_choice" =~ ^[1-3]$ ]]; then
  echo -e "\n  ${RED}❌ Invalid selection. Exiting.${NC}\n"
  exit 1
fi

# ── Production gate: checklist runs ONCE for prod + release ────
IS_PROD_RELEASE="false"
if [[ "$SEL_MAIN" == "lib/main_prod.dart" && "$SEL_MODE" == "release" ]]; then
  IS_PROD_RELEASE="true"
  run_production_checklist
fi

# ── First build (selected in Step 2) ─────────────────────────
build_artifact "$build_choice"

# ── Build-next loop (production only — checklist never repeats) ─
if [[ "$IS_PROD_RELEASE" == "true" ]]; then
  while true; do
    next_build_menu
    case "$next_choice" in
      1|2|3) build_artifact "$next_choice" ;;
      4)     echo -e "\n  ${GREEN}✔ Production release session complete. 🎉${NC}\n"; break ;;
      *)     echo -e "  ${RED}❌ Invalid selection — choose 1-4.${NC}" ;;
    esac
  done
fi
