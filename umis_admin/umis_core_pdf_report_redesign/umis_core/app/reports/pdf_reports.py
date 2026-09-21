"""
Ripoti za PDF (reportlab) - orodha za Wanachama/Uongozi kwa muundo wa
kitaaluma (jedwali). Inatofautiana na app/member/pdf_generator.py
(ambayo ni CV ya mtu MMOJA) - hizi ni ripoti za MAKUNDI ya watu.

MUONEKANO: banner ya kijani juu (kichwa cheupe + mstari/duara ndogo),
"meta bar" (tarehe ya kutengenezwa), kisha kila sehemu ya ripoti
inaonekana kama "kadi" yenye mstari wa kijani upande wa kushoto, icon
ya duara, kichwa, mstari mfupi, na jedwali (na mstari wa "Jumla"
ukihitajika) - kufuata muundo uliokubaliwa na Admin.
"""
import io
from datetime import datetime

from reportlab.graphics.shapes import Circle, Drawing
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Flowable, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

PRIMARY_GREEN = colors.HexColor("#008A3B")
HEADER_BG = colors.HexColor("#E6F6EC")
BORDER_GRAY = colors.HexColor("#E0E5E2")
TEXT_GRAY = colors.HexColor("#6B7280")


class _HeaderBanner(Flowable):
    """Banner ya kijani juu ya kila ripoti - kichwa cheupe katikati,
    na mstari mfupi + duara ndogo chini yake (kama muundo uliokubaliwa)."""

    def __init__(self, title: str, width: float, height: float = 2.6 * cm):
        super().__init__()
        self.title = title
        self.width = width
        self.height = height

    def wrap(self, avail_width, avail_height):
        return self.width, self.height

    def draw(self):
        c = self.canv
        c.setFillColor(PRIMARY_GREEN)
        c.roundRect(0, 0, self.width, self.height, 10, fill=1, stroke=0)

        c.setFillColor(colors.white)
        c.setFont("Helvetica-Bold", 19)
        c.drawCentredString(self.width / 2, self.height * 0.56, self.title)

        mid_y = self.height * 0.24
        line_half = 3.2 * cm
        c.setStrokeColor(colors.white)
        c.setLineWidth(1)
        c.line(self.width / 2 - line_half, mid_y, self.width / 2 - 9, mid_y)
        c.line(self.width / 2 + 9, mid_y, self.width / 2 + line_half, mid_y)
        c.setFillColor(colors.white)
        c.circle(self.width / 2, mid_y, 3.2, fill=1, stroke=0)


def _meta_bar(width: float, extra: str = "") -> Table:
    """Mstari wa taarifa chini ya banner - 'Imetengenezwa: tarehe/saa'."""
    now_text = f"Imetengenezwa: {datetime.now().strftime('%d/%m/%Y %H:%M')}"
    cell = [now_text] if not extra else [f"{now_text}      |      {extra}"]
    tbl = Table([cell], colWidths=[width])
    tbl.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 0.75, BORDER_GRAY),
        ("BACKGROUND", (0, 0), (-1, -1), colors.white),
        ("TEXTCOLOR", (0, 0), (-1, -1), colors.HexColor("#374151")),
        ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9.5),
        ("LEFTPADDING", (0, 0), (-1, -1), 16),
        ("TOPPADDING", (0, 0), (-1, -1), 10),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
    ]))
    return tbl


def _base_doc(title: str, extra_meta: str = ""):
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=landscape(A4),
        topMargin=1.0 * cm, bottomMargin=1.3 * cm, leftMargin=1.3 * cm, rightMargin=1.3 * cm,
    )
    content_width = doc.pagesize[0] - doc.leftMargin - doc.rightMargin

    story = [
        _HeaderBanner(title, content_width),
        Spacer(1, 12),
        _meta_bar(content_width, extra_meta),
        Spacer(1, 16),
    ]
    return buffer, doc, story, content_width


def _section_icon() -> Drawing:
    dwg = Drawing(24, 24)
    dwg.add(Circle(12, 12, 11, fillColor=PRIMARY_GREEN, strokeColor=None))
    return dwg


def _section(title, width, headers, rows, total_label=None, total_value=None, empty_message=None):
    """Kadi moja ya ripoti - mstari wa kijani upande wa kushoto, icon ya
    duara + kichwa, mstari mfupi, kisha jedwali (na 'Jumla' ikihitajika)."""
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("SecTitle", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=13, textColor=PRIMARY_GREEN)

    header_row = Table([[_section_icon(), Paragraph(title, title_style)]], colWidths=[28, None])
    header_row.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 0),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
    ]))

    divider = Table([[""]], colWidths=[5 * cm], rowHeights=[2])
    divider.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), PRIMARY_GREEN)]))

    inner = [header_row, Spacer(1, 6), divider, Spacer(1, 12)]
    available_table_width = width - 36  # (18pt left + 18pt right padding ya kadi)

    if not rows and empty_message:
        inner.append(Paragraph(empty_message, styles["Normal"]))
    else:
        data = [headers] + rows
        total_row_idx = None
        if total_label is not None and headers:
            total_row = [total_label] + [""] * (len(headers) - 2) + [str(total_value)]
            data.append(total_row)
            total_row_idx = len(data) - 1

        # Upana wa safu: jedwali la safu-2 (label/idadi) - safu ya kwanza
        # ipewe nafasi zaidi (70%) ili jedwali lizibe upana WOTE wa kadi
        # (kama muundo uliokubaliwa) - siyo kubaki finyu upande wa kushoto.
        if len(headers) == 2:
            col_widths = [available_table_width * 0.72, available_table_width * 0.28]
        else:
            col_widths = [available_table_width / len(headers)] * len(headers)

        table = Table(data, repeatRows=1, colWidths=col_widths)
        style_cmds = [
            ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
            ("TEXTCOLOR", (0, 0), (-1, 0), PRIMARY_GREEN),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("GRID", (0, 0), (-1, -1), 0.5, BORDER_GRAY),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("ALIGN", (0, 0), (-1, 0), "CENTER"),
            ("ALIGN", (1, 1), (-1, -1), "CENTER"),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#FAFBFA")]),
            ("TOPPADDING", (0, 0), (-1, -1), 6),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ]
        if total_row_idx is not None:
            style_cmds += [
                ("BACKGROUND", (0, total_row_idx), (-1, total_row_idx), HEADER_BG),
                ("FONTNAME", (0, total_row_idx), (-1, total_row_idx), "Helvetica-Bold"),
                ("TEXTCOLOR", (0, total_row_idx), (-1, total_row_idx), PRIMARY_GREEN),
                ("ALIGN", (0, total_row_idx), (-1, total_row_idx), "CENTER"),
            ]
            if len(headers) > 2:
                style_cmds.append(("SPAN", (0, total_row_idx), (-2, total_row_idx)))
        table.setStyle(TableStyle(style_cmds))
        inner.append(table)

    card = Table([[inner]], colWidths=[width])
    card.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 0.75, BORDER_GRAY),
        ("LINEBEFORE", (0, 0), (0, -1), 4, PRIMARY_GREEN),
        ("LEFTPADDING", (0, 0), (-1, -1), 18),
        ("RIGHTPADDING", (0, 0), (-1, -1), 18),
        ("TOPPADDING", (0, 0), (-1, -1), 16),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 16),
    ]))
    return card


# ---------------------------------------------------------------------
# Ripoti mbalimbali - kila moja sasa inatumia "_section()" (kadi) badala
# ya jedwali "wazi" tu, kwa muonekano thabiti kote.
# ---------------------------------------------------------------------

def generate_members_report_pdf(rulers: list) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Wanachama ({len(rulers)})")
    headers = ["#", "Jina Kamili", "Namba ya Uwanachama", "Simu", "Jinsia", "Hali"]
    rows = []
    for i, r in enumerate(rulers, start=1):
        full_name = " ".join(filter(None, [r.first_name, r.middle_name, r.last_name]))
        status = "Kiongozi" if getattr(r, "is_leader", False) else "Mwanachama"
        rows.append([str(i), full_name, r.membership_code or "-", r.phone_number or "-", r.gender or "-", status])
    story.append(_section("Orodha ya Wanachama", w, headers, rows, empty_message="Hakuna Wanachama wanaolingana na vigezo hivi."))
    doc.build(story)
    return buffer.getvalue()


def generate_leadership_report_pdf(positions: list, leadership_names: dict, region_names: dict, ruler_names: dict) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Uongozi ({len(positions)})")
    headers = ["#", "Jina la Mwanachama", "Nafasi", "Mkoa", "Kuanzia", "Hadi", "Hali"]
    rows = []
    for i, p in enumerate(positions, start=1):
        status = "Sasa" if p.is_verified and (p.end_date is None or p.end_date > datetime.now().date()) else ("Inasubiri" if not p.is_verified else "Historia")
        rows.append([
            str(i),
            ruler_names.get(p.ruler_id, f"#{p.ruler_id}"),
            leadership_names.get(p.leadership_id, f"#{p.leadership_id}"),
            region_names.get(p.region_id, "-"),
            str(p.start_date) if p.start_date else "-",
            str(p.end_date) if p.end_date else "Sasa",
            status,
        ])
    story.append(_section("Nafasi za Uongozi", w, headers, rows, empty_message="Hakuna nafasi za uongozi zinazolingana na vigezo hivi."))
    doc.build(story)
    return buffer.getvalue()


def generate_education_report_pdf(educations: list, ruler_names: dict) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Elimu ({len(educations)})")
    headers = ["#", "Jina la Mwanachama", "Mkoa", "Taasisi", "Ngazi", "Programu", "Kuanzia", "Hadi"]
    rows = []
    for i, e in enumerate(educations, start=1):
        rows.append([
            str(i),
            ruler_names.get(e.ruler_id, f"#{e.ruler_id}"),
            e.region or "-",
            e.institute or "-",
            e.education_level or "-",
            e.education_program or "-",
            str(e.start_date) if e.start_date else "-",
            str(e.end_date) if e.end_date else "-",
        ])
    story.append(_section("Taarifa za Elimu", w, headers, rows, empty_message="Hakuna taarifa za elimu zinazolingana na vigezo hivi."))
    doc.build(story)
    return buffer.getvalue()


def generate_summary_report_pdf(charts, level_rows: list) -> bytes:
    """Ripoti moja ya ukurasa mmoja - muhtasari wa idadi (siyo orodha ya
    watu binafsi) - Jinsia, Kiongozi-vs-Mwanachama, Wanachama kwa Mkoa,
    Wanachama kwa Ngazi ya Elimu."""
    buffer, doc, story, w = _base_doc("Ripoti ya Muhtasari (Idadi)")

    gender_total = sum(p.value for p in charts.gender_distribution)
    story.append(_section(
        "Jinsia za Wanachama", w, ["Jinsia", "Idadi"],
        [[p.label, str(p.value)] for p in charts.gender_distribution],
        total_label="Jumla", total_value=gender_total,
    ))
    story.append(Spacer(1, 16))

    leader_total = sum(p.value for p in charts.leader_vs_member)
    story.append(_section(
        "Kiongozi dhidi ya Mwanachama wa Kawaida", w, ["Hadhi", "Idadi"],
        [[p.label, str(p.value)] for p in charts.leader_vs_member],
        total_label="Jumla", total_value=leader_total,
    ))

    if charts.members_by_region:
        story.append(Spacer(1, 16))
        region_total = sum(p.value for p in charts.members_by_region)
        story.append(_section(
            "Wanachama kwa Mkoa (Top 8)", w, ["Mkoa", "Idadi"],
            [[p.label, str(p.value)] for p in charts.members_by_region],
            total_label="Jumla", total_value=region_total,
        ))

    if level_rows:
        story.append(Spacer(1, 16))
        level_total = sum(count for _, count in level_rows)
        story.append(_section(
            "Wanachama kwa Ngazi ya Elimu", w, ["Ngazi ya Elimu", "Idadi"],
            [[lvl or "-", str(count)] for lvl, count in level_rows],
            total_label="Jumla", total_value=level_total,
        ))

    doc.build(story)
    return buffer.getvalue()


def generate_region_branch_report_pdf(region_rows: list, branch_rows: list) -> bytes:
    """Ripoti maalum ya 'breakdown' kwa Mkoa NA Tawi (idadi kamili ya kila
    mmoja - siyo top 8 tu kama Muhtasari) - jedwali mbili tofauti."""
    buffer, doc, story, w = _base_doc("Ripoti kwa Mkoa/Tawi")

    region_total = sum(c for _, c in region_rows)
    story.append(_section(
        "Wanachama kwa Mkoa (Wote)", w, ["#", "Mkoa", "Idadi ya Wanachama"],
        [[str(i + 1), name, str(c)] for i, (name, c) in enumerate(region_rows)],
        total_label="Jumla", total_value=region_total,
        empty_message="Hakuna data bado.",
    ))
    story.append(Spacer(1, 16))

    branch_total = sum(c for _, _, c in branch_rows)
    story.append(_section(
        "Wanachama kwa Tawi (Wote)", w, ["#", "Tawi", "Mkoa", "Idadi ya Wanachama"],
        [[str(i + 1), name, region, str(c)] for i, (name, region, c) in enumerate(branch_rows)],
        total_label="Jumla", total_value=branch_total,
        empty_message="Hakuna data bado.",
    ))

    doc.build(story)
    return buffer.getvalue()


def generate_employment_report_pdf(employments: list, ruler_names: dict) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Ajira ({len(employments)})")
    headers = ["#", "Jina la Mwanachama", "Ajira", "Nafasi", "Mahali", "Kuanzia", "Hadi"]
    rows = []
    for i, e in enumerate(employments, start=1):
        rows.append([
            str(i), ruler_names.get(e.ruler_id, f"#{e.ruler_id}"), e.employment or "-", e.title or "-",
            e.place or "-", str(e.start_date) if e.start_date else "-", str(e.end_date) if e.end_date else "-",
        ])
    story.append(_section("Uzoefu wa Kazi", w, headers, rows, empty_message="Hakuna taarifa za ajira zinazolingana na vigezo hivi."))
    doc.build(story)
    return buffer.getvalue()


def generate_training_report_pdf(trainings: list, ruler_names: dict) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Mafunzo ({len(trainings)})")
    headers = ["#", "Jina la Mwanachama", "Aina", "Jina la Mafunzo", "Mahali", "Kuanzia", "Hadi"]
    rows = []
    for i, t in enumerate(trainings, start=1):
        rows.append([
            str(i), ruler_names.get(t.ruler_id, f"#{t.ruler_id}"), t.training_type or "-", t.training_name or "-",
            t.location or "-", str(t.start_date) if t.start_date else "-", str(t.end_date) if t.end_date else "-",
        ])
    story.append(_section("Mafunzo", w, headers, rows, empty_message="Hakuna taarifa za mafunzo zinazolingana na vigezo hivi."))
    doc.build(story)
    return buffer.getvalue()


def generate_occupation_report_pdf(occupation_rows: list) -> bytes:
    buffer, doc, story, w = _base_doc("Ripoti ya Kazi/Utaalamu")
    total = sum(c for _, c in occupation_rows)
    story.append(_section(
        "Idadi kwa Kazi/Utaalamu", w, ["Kazi/Utaalamu", "Idadi"],
        [[name or "Haijawekwa", str(c)] for name, c in occupation_rows],
        total_label="Jumla", total_value=total,
        empty_message="Hakuna data bado.",
    ))
    doc.build(story)
    return buffer.getvalue()


def generate_stakeholders_report_pdf(stakeholders: list) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Wadau ({len(stakeholders)})")
    headers = ["#", "Jina", "Aina", "Simu", "Barua Pepe", "Mtu wa Kuwasiliana"]
    rows = []
    for i, s in enumerate(stakeholders, start=1):
        rows.append([str(i), s.name, "Binafsi" if s.kind == "BINAFSI" else "Taasisi", s.phone_number or "-", s.email_address or "-", s.contact_person or "-"])
    story.append(_section("Orodha ya Wadau", w, headers, rows, empty_message="Hakuna Wadau wanaolingana na vigezo hivi."))
    doc.build(story)
    return buffer.getvalue()


def generate_accounts_report_pdf(with_account: list, without_account: list) -> bytes:
    buffer, doc, story, w = _base_doc(
        "Ripoti ya Akaunti za Kuingia",
        extra_meta=f"Wenye Akaunti: {len(with_account)}  \u2022  Wasio na Akaunti: {len(without_account)}",
    )
    headers = ["#", "Jina Kamili", "Namba ya Uwanachama", "Simu"]
    rows = [[str(i + 1), " ".join(filter(None, [r.first_name, r.last_name])), r.membership_code or "-", r.phone_number or "-"] for i, r in enumerate(without_account)]
    story.append(_section(
        "Wasio na Akaunti (Wanahitaji 'Tengeneza Akaunti')", w, headers, rows,
        empty_message="Wanachama wote wana akaunti tayari.",
    ))
    doc.build(story)
    return buffer.getvalue()


def generate_registration_period_report_pdf(rulers: list, start_date, end_date) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Usajili ({start_date} hadi {end_date})")
    headers = ["#", "Jina Kamili", "Namba ya Uwanachama", "Simu", "Tarehe ya Usajili"]
    rows = []
    for i, r in enumerate(rulers, start=1):
        full_name = " ".join(filter(None, [r.first_name, r.last_name]))
        rows.append([str(i), full_name, r.membership_code or "-", r.phone_number or "-", r.created_at.strftime("%Y-%m-%d") if r.created_at else "-"])
    story.append(_section(f"Wanachama Waliojisajili ({start_date} - {end_date})", w, headers, rows, empty_message="Hakuna aliyejisajili kwenye kipindi hiki."))
    doc.build(story)
    return buffer.getvalue()


def generate_incomplete_profile_report_pdf(rulers: list) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Taarifa Zisizokamilika ({len(rulers)})")
    headers = ["#", "Jina Kamili", "Namba ya Uwanachama", "Kinachokosekana"]
    rows = []
    for i, r in enumerate(rulers, start=1):
        missing = []
        if not r.phone_number:
            missing.append("Simu")
        if not r.email_address:
            missing.append("Barua Pepe")
        if not r.member_photo:
            missing.append("Picha")
        if not r.region_id:
            missing.append("Mkoa")
        full_name = " ".join(filter(None, [r.first_name, r.last_name]))
        rows.append([str(i), full_name, r.membership_code or "-", ", ".join(missing)])
    story.append(_section("Wanachama Wenye Taarifa Zisizokamilika", w, headers, rows, empty_message="Wanachama wote wana taarifa kamili."))
    doc.build(story)
    return buffer.getvalue()


def generate_pending_verification_report_pdf(positions: list, leadership_names: dict, region_names: dict, ruler_names: dict) -> bytes:
    buffer, doc, story, w = _base_doc(f"Ripoti ya Uthibitisho Unaosubiri ({len(positions)})")
    headers = ["#", "Jina la Mwanachama", "Nafasi", "Mkoa", "Aliyejiongezea Tarehe"]
    rows = []
    for i, p in enumerate(positions, start=1):
        rows.append([
            str(i), ruler_names.get(p.ruler_id, f"#{p.ruler_id}"), leadership_names.get(p.leadership_id, f"#{p.leadership_id}"),
            region_names.get(p.region_id, "-"), p.created_at.strftime("%Y-%m-%d") if p.created_at else "-",
        ])
    story.append(_section("Nafasi Zinazosubiri Uthibitisho", w, headers, rows, empty_message="Hakuna nafasi zinazosubiri uthibitisho kwa sasa."))
    doc.build(story)
    return buffer.getvalue()
