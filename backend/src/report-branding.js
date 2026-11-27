import {fileURLToPath} from 'node:url';

const logoPath=fileURLToPath(new URL('../assets/hasani_payroll_logo.png',import.meta.url));
export function drawReportLogo(doc, x, y, {width = 220, height = 34} = {}) {
  doc.image(logoPath, x, y, {fit: [width, height], align: 'center', valign: 'center'});
}
