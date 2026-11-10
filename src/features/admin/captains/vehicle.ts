import type { Captain, VehicleType } from '@/domain/types';

export const VEHICLE_LABEL: Record<VehicleType, string> = { motorcycle: 'دراجة نارية', car: 'سيارة', bicycle: 'دراجة هوائية' };

/**
 * Vehicle shown for a Captain. The add/edit form no longer collects vehicle details, so new
 * Captains have none; older records keep theirs (read-only display).
 */
export function vehicleText(captain: Pick<Captain, 'vehicleType' | 'vehicleDescription'>): string {
  if (!captain.vehicleType) return 'غير محددة';
  const label = VEHICLE_LABEL[captain.vehicleType];
  return captain.vehicleDescription ? `${label} — ${captain.vehicleDescription}` : label;
}
