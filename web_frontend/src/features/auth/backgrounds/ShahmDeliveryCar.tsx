import './shahm-delivery-car.css';

/** Official SHAHM delivery car photo, served locally and never altered (transparent PNG). */
export const SHAHM_CAR_SRC = '/brand/shahm-car.png';
const CAR_WIDTH = 1672;
const CAR_HEIGHT = 941;

/**
 * The branded SHAHM car driving left → right (it faces right) along a faint road in the
 * lower part of the login brand panel, looping seamlessly: it fully leaves one edge before
 * re-entering from the other. Transform-only CSS, no re-renders; parked under reduced motion.
 * Decorative and non-interactive, behind the watermark and all copy.
 */
export function ShahmDeliveryCar() {
  return (
    <div className="shahm-car-lane" aria-hidden="true">
      <div className="shahm-car-road">
        <div className="shahm-car-lanemark" />
      </div>
      <div className="shahm-car-run">
        <img className="shahm-car" src={SHAHM_CAR_SRC} width={CAR_WIDTH} height={CAR_HEIGHT} alt="" draggable={false} decoding="async" />
      </div>
    </div>
  );
}
