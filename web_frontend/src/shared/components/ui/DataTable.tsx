import type { ReactNode } from 'react';
import { InfoTooltip } from './InfoTooltip';

export const ACTIONS_HEADER = 'الإجراءات';

export interface ActionLegendItem {
  icon: ReactNode;
  label: string;
}

/**
 * The one admin table standard (Master Prompt §13): labelled headers, a visible separator
 * between every column (RTL-safe logical borders), exactly two alternating row colours, and
 * an «الإجراءات» header whose help icon explains only the icons this table uses.
 * Rows are passed as children so each feature keeps its own cells; put actions in `<RowActions>`.
 */
export function DataTable({
  headers,
  actionsLegend,
  minWidth = 760,
  children,
}: {
  /** Column labels, excluding the actions column (added when `actionsLegend` is set). */
  headers: ReactNode[];
  actionsLegend?: ActionLegendItem[];
  minWidth?: number;
  children: ReactNode;
}) {
  return (
    <div className="overflow-x-auto">
      <table
        className="w-full text-sm [&_td:first-child]:border-s-0 [&_td]:border-s [&_td]:border-cream-deep [&_th:first-child]:border-s-0 [&_th]:border-s [&_th]:border-cream-deep"
        style={{ minWidth }}
      >
        <thead className="bg-cream-dark/70 text-xs text-ink-soft">
          <tr>
            {headers.map((h, i) => (
              <th key={i} scope="col" className="whitespace-nowrap px-4 py-3 text-start font-bold">{h}</th>
            ))}
            {actionsLegend && (
              <th scope="col" className="w-px whitespace-nowrap px-3 py-3 text-start font-bold">
                <span className="inline-flex items-center gap-1">
                  {ACTIONS_HEADER}
                  <InfoTooltip
                    icon="alert"
                    align="end"
                    label="شرح أيقونات الإجراءات"
                    text={
                      <span className="block space-y-1.5">
                        {actionsLegend.map((a) => (
                          <span key={a.label} className="flex items-center gap-2">
                            <span className="shrink-0 [&>svg]:h-4 [&>svg]:w-4" aria-hidden>{a.icon}</span>
                            {a.label}
                          </span>
                        ))}
                      </span>
                    }
                  />
                </span>
              </th>
            )}
          </tr>
        </thead>
        <tbody className="divide-y divide-cream-deep [&>tr:nth-child(even)]:bg-cream/60 [&>tr:nth-child(odd)]:bg-white">{children}</tbody>
      </table>
    </div>
  );
}

/** The actions cell: icon buttons only. */
export function RowActions({ children }: { children: ReactNode }) {
  return (
    <td className="w-px whitespace-nowrap px-3 py-2">
      <div className="flex items-center gap-0.5">{children}</div>
    </td>
  );
}
