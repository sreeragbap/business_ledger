/** Mirrors `Currency.supported` in `lib/core/money/currency.dart`. */
export interface Currency {
  code: string;
  decimals: number;
  symbol: string;
}

export const CURRENCIES: Currency[] = [
  {code: "INR", decimals: 2, symbol: "₹"},
  {code: "USD", decimals: 2, symbol: "$"},
  {code: "EUR", decimals: 2, symbol: "€"},
  {code: "GBP", decimals: 2, symbol: "£"},
  {code: "AED", decimals: 2, symbol: "AED "},
  {code: "SAR", decimals: 2, symbol: "SAR "},
  {code: "JPY", decimals: 0, symbol: "¥"},
  {code: "KWD", decimals: 3, symbol: "KWD "},
];

export const currencyByCode = (code: string): Currency | undefined => CURRENCIES.find((c) => c.code === code);
