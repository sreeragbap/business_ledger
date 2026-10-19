/**
 * Starting structures for a new business. Everything seeded here is an
 * ordinary category/field the owner can rename, reorder or archive; a
 * template is a convenience, never a constraint.
 */

/** Built-in form sections a business can switch on or off. Keys shared with Dart `StandardField`. */
export const STANDARD_FIELDS = [
  "lineItems", "party", "project", "paymentMethod", "dueDate", "reference", "notes",
] as const;
export type StandardField = (typeof STANDARD_FIELDS)[number];

export const FIELD_TYPES = ["text", "number", "date", "select", "checkbox"] as const;
export type FieldType = (typeof FIELD_TYPES)[number];

export type CategoryKind = "income" | "expense" | "any";

export interface TemplateField {
  key: string;
  label: string;
  type: FieldType;
  options?: string[];
  required?: boolean;
}

export interface TemplateCategory {
  name: string;
  kind: CategoryKind;
  icon: string;
  colour: string;
  fields?: string[];
}

export interface Template {
  key: string;
  label: string;
  standardFields: StandardField[];
  fields: TemplateField[];
  categories: TemplateCategory[];
}

const common: StandardField[] = ["party", "paymentMethod", "dueDate", "reference", "notes"];

export const TEMPLATES: Record<string, Template> = {
  general: {
    key: "general",
    label: "General",
    standardFields: [...common, "lineItems"],
    fields: [],
    categories: [
      {name: "Sales", kind: "income", icon: "sell", colour: "green"},
      {name: "Other income", kind: "income", icon: "savings", colour: "teal"},
      {name: "Purchases", kind: "expense", icon: "shopping", colour: "amber"},
      {name: "Rent", kind: "expense", icon: "home", colour: "purple"},
      {name: "Salaries", kind: "expense", icon: "people", colour: "blue"},
      {name: "Other expenses", kind: "expense", icon: "receipt", colour: "grey"},
    ],
  },
  retail: {
    key: "retail",
    label: "Retail",
    standardFields: [...common, "lineItems"],
    fields: [{key: "sku", label: "SKU / item code", type: "text"}],
    categories: [
      {name: "Product sales", kind: "income", icon: "sell", colour: "green", fields: ["sku"]},
      {name: "Stock purchases", kind: "expense", icon: "inventory", colour: "amber", fields: ["sku"]},
      {name: "Supplier payments", kind: "expense", icon: "payments", colour: "orange"},
      {name: "Rent", kind: "expense", icon: "home", colour: "purple"},
      {name: "Utilities", kind: "expense", icon: "bolt", colour: "blue"},
      {name: "Other expenses", kind: "expense", icon: "receipt", colour: "grey"},
    ],
  },
  construction: {
    key: "construction",
    label: "Construction",
    standardFields: [...common, "lineItems", "project"],
    fields: [
      {key: "site", label: "Site", type: "text"},
      {key: "unit", label: "Unit", type: "select", options: ["bags", "kg", "tonnes", "m³", "ft", "nos", "days", "hours"]},
      {key: "vehicle", label: "Vehicle no.", type: "text"},
    ],
    categories: [
      {name: "Contract income", kind: "income", icon: "sell", colour: "green"},
      {name: "Materials", kind: "expense", icon: "inventory", colour: "amber", fields: ["site", "unit"]},
      {name: "Labour", kind: "expense", icon: "people", colour: "blue", fields: ["site"]},
      {name: "Transport", kind: "expense", icon: "truck", colour: "orange", fields: ["vehicle"]},
      {name: "Equipment rental", kind: "expense", icon: "build", colour: "purple", fields: ["site"]},
      {name: "Contractor payments", kind: "expense", icon: "payments", colour: "teal"},
      {name: "Other expenses", kind: "expense", icon: "receipt", colour: "grey"},
    ],
  },
  services: {
    key: "services",
    label: "Services",
    standardFields: [...common, "lineItems", "project"],
    fields: [{key: "hours", label: "Hours", type: "number"}],
    categories: [
      {name: "Service fees", kind: "income", icon: "sell", colour: "green", fields: ["hours"]},
      {name: "Retainers", kind: "income", icon: "savings", colour: "teal"},
      {name: "Software", kind: "expense", icon: "laptop", colour: "blue"},
      {name: "Travel", kind: "expense", icon: "flight", colour: "orange"},
      {name: "Subcontractors", kind: "expense", icon: "people", colour: "purple"},
      {name: "Other expenses", kind: "expense", icon: "receipt", colour: "grey"},
    ],
  },
  blank: {
    key: "blank",
    label: "Start empty",
    standardFields: [...common],
    fields: [],
    categories: [],
  },
};
