/** Synchronous Node24.15.0/ICU78.2 byte API. Runtime validation remains authoritative. */
export interface SavOptions {
  /** Explicit supported encoding or alias. Omitted/undefined uses source declarations. */
  encoding?: string | undefined;
  /** Positive integer, at most1,000,000; cannot raise the compiled limit. */
  maxRows?: number | undefined;
  /** Positive integer, at most268,435,456 bytes. */
  maxInputBytes?: number | undefined;
  /** Positive integer, at most536,870,912 bytes. */
  maxOutputBytes?: number | undefined;
}
export type SavEncodingName = 'utf-8' | 'windows-1252' | 'gbk' | 'gb18030';
export interface SavEncoding {
  declared: string | null;
  machine_code: number | null;
  effective: SavEncodingName;
  selection_source: 'override' | 'record20' | 'machine_code';
  profile: `${SavEncodingName}/moonsav-1`;
  string_matching_policy: 'source-bytes-space-padded-width-v1';
  decoder_identity: string;
}
export interface SavWarning {warning_code: string; scope: string; suggested_action: string;}
export interface SavExtra {record: number; subtype: number | null; byte_offset: number; raw_base64: string;}
export interface SavFormat {raw: number; code: number; width: number; decimals: number;}
export interface SavNumericAtom {
  type: 'numeric'; decimal: string; ieee754_hex: string;
  text: null; logical_bytes_base64: null; width: 8;
  endpoint: 'finite' | 'lowest' | 'highest' | null;
}
export interface SavStringAtom {
  type: 'string'; decimal: null; ieee754_hex: null;
  text: string; logical_bytes_base64: string; width: number; endpoint: null;
}
export type SavAtom = SavNumericAtom | SavStringAtom;
export interface SavValueLabel {value: SavAtom; label: string; raw_label_base64: string;}
export interface SavUserMissing {kind: 'discrete' | 'range' | 'range_plus_discrete'; values: SavAtom[];}
export interface SavVariable {
  index: number; name: string; short_name: string; type: 'numeric' | 'string'; width: number;
  label: string | null; raw_label_base64: string | null;
  source_offset: number; physical_start: number; physical_slots: number;
  print_format: SavFormat; write_format: SavFormat;
  value_labels: SavValueLabel[]; user_missing: SavUserMissing;
  measure: 0 | 1 | 2 | 3 | null; display_width: number | null; alignment: 0 | 1 | 2 | null;
}
export interface SavCsvPolicy {
  numeric_system_missing: 'empty_field'; string_escape: 'csv_quotes_only';
  date_policy: 'raw'; encoding: 'utf-8'; record_separator: 'CRLF';
}
/** A dictionary snapshot; actual_rows stays null even in a collected read result. */
export interface SavDictionary {
  schema_version: 'moonsav.metadata/1'; validation_scope: 'dictionary_only';
  declared_rows: number | null; actual_rows: null; logical_variables: number;
  variables: SavVariable[]; encoding: SavEncoding;
  file_label: string; creation_date: string; creation_time: string; product: string;
  weight_variable: number | null; compression: 0 | 1; bias: number;
  physical_slots: number; nominal_case_size: number;
  system_missing_hex: string; lowest_hex: string; highest_hex: string;
  warnings: SavWarning[]; uninterpreted_metadata: SavExtra[]; csv: SavCsvPolicy;
}
export interface SavNumericCell {
  kind: 'numeric'; missing: 'present' | 'user'; decimal: string; ieee754_hex: string;
  text: null; logical_bytes_base64: null;
}
export interface SavSystemMissingCell {
  kind: 'numeric'; missing: 'system'; decimal: null; ieee754_hex: string;
  text: null; logical_bytes_base64: null;
}
export interface SavStringCell {
  kind: 'string'; missing: 'present' | 'user'; decimal: null; ieee754_hex: null;
  text: string; logical_bytes_base64: string;
}
export type SavCell = SavNumericCell | SavSystemMissingCell | SavStringCell;
/** Rows are collected only after a complete scan. Returned arrays are mutable snapshots. */
export interface SavDataset {dictionary: SavDictionary; rows: SavCell[][];}
export interface SavErrorInfo {
  /** Open identifier; callers must handle unfamiliar error codes. */
  code: string; message: string;
  byte_offset?: number | null | undefined; record?: number | null | undefined;
  subtype?: number | null | undefined; variable_index?: number | null | undefined;
  row_index?: number | null | undefined; actual?: number | null | undefined;
  limit?: number | null | undefined;
}
export class SavError extends Error implements SavErrorInfo {
  constructor(info: SavErrorInfo);
  code: string;
  byte_offset?: number | null | undefined; record?: number | null | undefined;
  subtype?: number | null | undefined; variable_index?: number | null | undefined;
  row_index?: number | null | undefined; actual?: number | null | undefined;
  limit?: number | null | undefined;
}
/** Validates the dictionary; does not scan cases or promise valid data EOF. */
export function inspectSav(input: Uint8Array, options?: SavOptions): SavDictionary;
/** Fully scans and collects rows. Input must remain stable until synchronous return. */
export function readSav(input: Uint8Array, options?: SavOptions): SavDataset;
