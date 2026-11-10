// Shared UI primitives — one component (or tightly related pair) per file.
// Feature code imports from '@/shared/components/ui'; these files never import features.
export { Button, type ButtonProps, type ButtonVariant } from './Button';
export { Card, CardHeader } from './Card';
export { Badge } from './Badge';
export { SimTag, OpenDecision } from './DemoLabels';
export { Field, fieldMessageId } from './Field';
export { Input, Textarea, Select, inputBase } from './Inputs';
export { SearchField } from './SearchField';
export { PasswordField } from './PasswordField';
export { PhoneField, PHONE_HINT } from './PhoneField';
export { InfoTooltip } from './InfoTooltip';
export { DataTable, RowActions, ACTIONS_HEADER, type ActionLegendItem } from './DataTable';
export { IconAction } from './IconAction';
export { InputIcon, INPUT_ICON_PAD } from './InputIcon';
export { Toggle } from './Toggle';
export { Dialog, ConfirmDialog } from './Dialog';
export { Drawer } from './Drawer';
export { EmptyState } from './EmptyState';
export { PageHeader } from './PageHeader';
export { StatCard } from './StatCard';
export { DetailRow } from './DetailRow';
export { Tabs } from './Tabs';
export { SettingsSection, SettingsRow } from './Settings';
