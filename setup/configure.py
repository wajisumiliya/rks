"""Apply company identity to a fresh copy of the payroll source."""
import argparse
import html
import json
from pathlib import Path
import re

from PIL import Image

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("config", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
config = json.loads(args.config.read_text(encoding="utf-8"))
values = {
    "Payroll Company": config["company_name"],
    "Company Payroll": config["portal_name"],
    "hr@example.invalid": config["hr_email"],
    "example.invalid": config["website"],
}
if any(not isinstance(v, str) or not v.strip() or '\n' in v or '\r' in v for v in values.values()):
    parser.error("Identity fields must be nonempty single-line strings.")
logo = Image.open(args.config.parent / config["logo"]).convert("RGBA")
pattern = re.compile("|".join(re.escape(k) for k in values))
state_path = root / "setup/.branding-state.json"
if state_path.exists():
    parser.error("Apply configuration to a fresh copy of the template source.")
for folder in ("lib", "backend/src", "web", "android/app/src/main", "ios/Runner"):
    for path in (root / folder).rglob("*"):
        suffix = path.suffix
        if suffix not in (".dart", ".js", ".html", ".json", ".xml", ".plist"):
            continue
        text = path.read_text(encoding="utf-8")
        def substitute(match):
            value = values[match[0]]
            if suffix in (".html", ".xml", ".plist"):
                return html.escape(value, quote=True)
            if suffix == ".json":
                return json.dumps(value, ensure_ascii=False)[1:-1]
            value = value.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"')
            return value.replace("$", "\\$") if suffix == ".dart" else value.replace("`", "\\`").replace("${", "\\${")
        branded = pattern.sub(substitute, text)
        if branded != text:
            path.write_text(branded, encoding="utf-8")
for path in (
    "assets/hasani_books_logo.jpg",
    "assets/hasani_books_logo_card.jpg",
    "assets/hasani_books_payslip_logo.jpeg",
    "assets/Hasani Payroll Logo.png",
    "assets/hb_payroll_icon.png",
    "backend/assets/hasani_payroll_logo.png",
):
    target = root / path
    if target.suffix in (".jpg", ".jpeg"):
        canvas = Image.new("RGB", logo.size, "white")
        canvas.paste(logo, mask=logo.getchannel("A"))
        canvas.save(target, quality=95)
    else:
        logo.save(target)
icon_paths = list((root / "web/icons").glob("*.png"))
for pattern in (
    "android/app/src/main/res/*/ic_launcher*.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png",
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png",
    "assets/branch_stamps/*.png",
):
    icon_paths.extend(root.glob(pattern))
for path in icon_paths:
    if path.stat().st_size == 0:
        canvas = Image.new("RGBA", (1024, 1024), "white")
    else:
        with Image.open(path) as original:
            canvas = Image.new("RGBA", original.size, "white")
    icon = logo.copy()
    icon.thumbnail(canvas.size, Image.Resampling.LANCZOS)
    canvas.alpha_composite(icon, ((canvas.width-icon.width)//2, (canvas.height-icon.height)//2))
    canvas.save(path)
state_path.write_text(json.dumps(config), encoding="utf-8")
