import {describe, expect, it} from "vitest";
import {
  cleanResult,
  OUTPUT_SCHEMA,
  parseRequest,
  type ScanRequest,
  SYSTEM_PROMPT,
  userPrompt,
  validGstin,
} from "../../functions/scan-receipt/receipt.ts";

const request: ScanRequest = {
  text: "RELIANCE FRESH\nGrand Total 955.00",
  currency: "INR",
  today: "2026-10-26",
  categories: [{id: "cat-groceries", name: "Groceries"}],
};

const answer = {
  merchant: "Reliance Fresh",
  date: "2026-10-24",
  total: "955.00",
  currency: "INR",
  reference: "RF/2026/04821",
  paymentMethod: "UPI",
  categoryId: "cat-groceries",
  description: "Groceries",
  lineItems: [{description: "Toor Dal 1kg", quantity: "2", rate: "145.00"}],
  sellerGstin: "32AAHFC5361P1Z7",
  sellerPhone: "8606206660",
  sellerEmail: "mail@calicuttyres.com",
  sellerAddress: "Thondayad Bypass Road, Calicut 673016",
};

describe("scan-receipt parseRequest", () => {
  it("accepts a well-formed body and drops malformed categories", () => {
    const parsed = parseRequest({
      ...request,
      categories: [...request.categories, {id: 5}, null, {id: "x", name: ""}],
    });
    expect(parsed).toEqual(request);
  });

  it("rejects missing text, bad currency, bad date and huge input", () => {
    expect(parseRequest({...request, text: " "})).toBe("text is required");
    expect(parseRequest({...request, currency: "rupees"})).toMatch(/currency/);
    expect(parseRequest({...request, today: "26/10/2026"})).toMatch(/today/);
    expect(parseRequest({...request, text: "x".repeat(12001)})).toMatch(/long/);
    expect(parseRequest("nope")).toMatch(/JSON/);
  });
});

describe("scan-receipt cleanResult", () => {
  it("keeps a valid answer as is", () => {
    expect(cleanResult(answer, request)).toEqual(answer);
  });

  it("drops a category id that was not offered", () => {
    expect(cleanResult({...answer, categoryId: "made-up"}, request).categoryId)
      .toBeNull();
  });

  it("drops future and impossible dates but allows tomorrow", () => {
    expect(cleanResult({...answer, date: "2026-11-02"}, request).date).toBeNull();
    expect(cleanResult({...answer, date: "2026-02-30"}, request).date).toBeNull();
    expect(cleanResult({...answer, date: "2026-10-27"}, request).date)
      .toBe("2026-10-27");
  });

  it("only accepts plain positive decimal totals", () => {
    expect(cleanResult({...answer, total: "1,240.50"}, request).total)
      .toBe("1240.50");
    expect(cleanResult({...answer, total: "about 900"}, request).total)
      .toBeNull();
    expect(cleanResult({...answer, total: "0"}, request).total).toBeNull();
  });

  it("drops a malformed GSTIN or email", () => {
    const cleaned = cleanResult(
      {...answer, sellerGstin: "32AAHFC", sellerEmail: "not an email"},
      request,
    );
    expect(cleaned.sellerGstin).toBeNull();
    expect(cleaned.sellerEmail).toBeNull();
    expect(cleaned.sellerPhone).toBe("8606206660");
  });

  it("drops a GSTIN whose check character is wrong", () => {
    expect(cleanResult({...answer, sellerGstin: "32AAHFC5361P1Z8"}, request)
      .sellerGstin).toBeNull();
    expect(validGstin("27AAPFU0939F1ZV")).toBe(true);
  });

  it("tells the model the ₹ sign can read as a digit", () => {
    expect(SYSTEM_PROMPT).toContain("amount in words");
  });

  it("only accepts the known payment methods", () => {
    expect(cleanResult({...answer, paymentMethod: "Bitcoin"}, request)
      .paymentMethod).toBeNull();
  });

  it("skips unreadable line items and caps long text", () => {
    const cleaned = cleanResult({
      ...answer,
      merchant: "M".repeat(100),
      lineItems: [
        {description: "Rice", quantity: "two", rate: "50"},
        {description: "", quantity: "1", rate: "50"},
        {description: "Oil", quantity: "1", rate: "1,200.00"},
      ],
    }, request);
    expect(cleaned.merchant).toHaveLength(60);
    expect(cleaned.lineItems).toEqual([
      {description: "Oil", quantity: "1", rate: "1200.00"},
    ]);
  });

  it("turns anything that is not an object into an empty result", () => {
    expect(cleanResult(null, request)).toEqual({
      merchant: null,
      date: null,
      total: null,
      currency: null,
      reference: null,
      paymentMethod: null,
      categoryId: null,
      description: null,
      lineItems: [],
      sellerGstin: null,
      sellerPhone: null,
      sellerEmail: null,
      sellerAddress: null,
    });
  });
});

describe("scan-receipt prompt and schema", () => {
  it("lists the categories and the receipt text", () => {
    const prompt = userPrompt(request);
    expect(prompt).toContain("cat-groceries: Groceries");
    expect(prompt).toContain("Grand Total 955.00");
    expect(prompt).toContain("Today: 2026-10-26");
  });

  it("asks for line items that add up to the total", () => {
    expect(SYSTEM_PROMPT).toContain("must add up exactly to total");
    expect(SYSTEM_PROMPT).toContain("Rate (Incl. of Tax)");
    expect(SYSTEM_PROMPT).toContain("SGST 14%");
  });

  it("requires every property so the answer shape is fixed", () => {
    expect([...OUTPUT_SCHEMA.required].sort())
      .toEqual(Object.keys(OUTPUT_SCHEMA.properties).sort());
  });
});
