import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/backup_service.dart';
import '../services/dashboard_service.dart';

/// Shared HTML layout shell for all dashboard pages.
///
/// Provides sidebar navigation, responsive hamburger menu, dark/light
/// theme toggle, and CSS custom property theming.
String dashboardShell({
  required String title,
  required String activeNav,
  required String content,
  required String apiKey,
  Request? request,
  BackupService? backupService,
  String extraHead = '',
  String extraScripts = '',
}) {
  final selectedBackup = request != null ? _selectedBackup(request) : null;
  final backups = backupService?.listBackups() ?? const <BackupInfo>[];
  final currentPath = request != null ? '/${request.url.path}' : '/dashboard';
  final queryParameters =
      request?.url.queryParameters ?? const <String, String>{};
  final savePicker = _buildSavePicker(
    apiKey: apiKey,
    currentPath: currentPath,
    queryParameters: queryParameters,
    backups: backups,
    selectedBackup: selectedBackup,
  );

  String navItem(String label, String path, String icon) {
    final isActive = label.toLowerCase() == activeNav.toLowerCase();
    final activeClass = isActive ? ' class="active"' : '';
    final href = _dashboardHref(path, apiKey, selectedBackup);
    return '<a href="$href"$activeClass><span class="nav-icon">$icon</span> $label</a>';
  }

  return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="referrer" content="no-referrer">
<title>$title - JackedLog</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    color-scheme: dark;
    --bg: #0d0f0c;
    --surface: #151913;
    --surface-elevated: #1f241c;
    --surface-strong: #293025;
    --text: #f4f1e9;
    --text-muted: #a7ad9c;
    --accent: #9fc46d;
    --accent-dim: rgba(159,196,109,0.16);
    --accent-hover: #b8d982;
    --teal: #74b6a3;
    --green: #9fc46d;
    --amber: #d6a15d;
    --red: #e06d5f;
    --border: rgba(225,231,211,0.12);
    --shadow: 0 1px 2px rgba(0,0,0,0.32), 0 18px 48px rgba(0,0,0,0.22);
    --radius: 10px;
  }
  html.light {
    color-scheme: light;
    --bg: #f5f3ee;
    --surface: #fffdf7;
    --surface-elevated: #eeeadf;
    --surface-strong: #e2dccd;
    --text: #1d2119;
    --text-muted: #6b725f;
    --accent: #617d3f;
    --accent-dim: rgba(97,125,63,0.12);
    --accent-hover: #4d6531;
    --border: rgba(45,52,36,0.13);
    --shadow: 0 1px 2px rgba(45,52,36,0.08), 0 18px 38px rgba(45,52,36,0.09);
  }
  *, *::before, *::after { box-sizing: border-box; }
  html { background: var(--bg); scroll-behavior: smooth; }
  body {
    background:
      radial-gradient(900px 520px at 88% -10%, var(--accent-dim), transparent 62%),
      radial-gradient(700px 520px at 8% 18%, rgba(214,161,93,0.07), transparent 55%),
      var(--bg);
    background-attachment: fixed;
    color: var(--text);
    font-family: "Outfit", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    font-feature-settings: "cv02", "cv03", "cv04", "tnum";
    margin: 0;
  }
  body::before {
    content: "";
    position: fixed;
    inset: 0;
    pointer-events: none;
    opacity: 0.18;
    background-image:
      linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(255,255,255,0.035) 1px, transparent 1px);
    background-size: 34px 34px;
    mask-image: linear-gradient(to bottom, #000 0%, transparent 72%);
  }
  a { color: var(--accent); }
  a, button, input, select {
    transition: background 0.18s ease, border-color 0.18s ease, color 0.18s ease, transform 0.18s ease, box-shadow 0.18s ease;
  }
  a:focus-visible, button:focus-visible, input:focus-visible, select:focus-visible {
    outline: 2px solid var(--accent);
    outline-offset: 3px;
  }
  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    width: 240px;
    height: 100vh;
    background: color-mix(in srgb, var(--surface) 88%, #000 12%);
    border-right: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    z-index: 100;
    transition: transform 0.2s ease;
  }
  .sidebar .logo {
    padding: 1.35rem 1.25rem;
    font-size: 1.25rem;
    font-weight: 800;
    color: var(--text);
    border-bottom: 1px solid var(--border);
  }
  .sidebar .logo::after {
    content: "";
    display: block;
    width: 42px;
    height: 3px;
    margin-top: 0.45rem;
    border-radius: 999px;
    background: var(--accent);
  }
  .sidebar nav { display: flex; flex-direction: column; gap: 2px; padding: 0.75rem 0.6rem; flex: 1; }
  .sidebar nav a {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    padding: 0.62rem 0.75rem;
    color: var(--text-muted);
    text-decoration: none;
    font-size: 0.88rem;
    font-weight: 500;
    border-radius: 8px;
  }
  .sidebar nav a .nav-icon { display: inline-flex; opacity: 0.75; }
  .sidebar nav a:hover { background: var(--surface-elevated); color: var(--text); transform: translateX(2px); }
  .sidebar nav a.active {
    background: var(--accent-dim);
    color: var(--text);
    font-weight: 650;
    box-shadow: inset 3px 0 0 var(--accent);
  }
  .sidebar nav a.active .nav-icon { color: var(--accent); opacity: 1; }
  .main {
    margin-left: 240px;
    min-height: 100dvh;
  }
  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.85rem 1.5rem;
    border-bottom: 1px solid var(--border);
    background: color-mix(in srgb, var(--surface) 86%, transparent);
    backdrop-filter: blur(14px);
    position: sticky;
    top: 0;
    z-index: 50;
  }
  .header h1 { font-size: 1.08rem; margin: 0; font-weight: 700; letter-spacing: 0; }
  .header-left { display: flex; align-items: center; gap: 0.75rem; }
  .header-actions { display: flex; align-items: center; gap: 0.65rem; }
  .hamburger {
    display: none;
    background: none;
    border: none;
    color: var(--text);
    font-size: 1.4rem;
    cursor: pointer;
    padding: 0.25rem;
  }
  .save-picker {
    display: flex;
    align-items: center;
    gap: 0.45rem;
  }
  .save-picker label {
    color: var(--text-muted);
    font-size: 0.78rem;
    font-weight: 600;
  }
  .save-picker select {
    min-width: 210px;
    max-width: 320px;
    height: 36px;
    padding: 0 2rem 0 0.75rem;
    border: 1px solid var(--border);
    border-radius: 8px;
    background: var(--surface-elevated);
    color: var(--text);
    font: inherit;
    font-size: 0.85rem;
  }
  .theme-toggle {
    background: var(--surface-elevated);
    border: 1px solid var(--border);
    color: var(--text);
    font-size: 1.1rem;
    cursor: pointer;
    padding: 0.3rem 0.5rem;
    border-radius: 8px;
    line-height: 1;
  }
  .theme-toggle:hover { background: var(--surface-strong); transform: translateY(-1px); }
  .overlay {
    display: none;
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0,0,0,0.5);
    z-index: 90;
  }
  .content {
    width: min(100%, 1440px);
    margin: 0 auto;
    padding: 1.35rem;
  }
  .empty-state {
    color: var(--text-muted);
    padding: 4rem 1rem;
    text-align: center;
  }
  .empty-state p:first-child {
    color: var(--text);
    font-size: 1.15rem;
    font-weight: 650;
    margin-bottom: 0.5rem;
  }
  .metric-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 1rem;
    margin-bottom: 1.25rem;
  }
  .metric-card,
  .panel,
  .block-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
  }
  .metric-card {
    position: relative;
    overflow: hidden;
    min-height: 112px;
    padding: 1.15rem;
    isolation: isolate;
  }
  .metric-card:hover { transform: translateY(-2px); border-color: color-mix(in srgb, var(--metric-color, var(--accent)) 45%, var(--border)); }
  .metric-card::before {
    content: "";
    position: absolute;
    inset: 0 0 auto 0;
    height: 3px;
    background: linear-gradient(90deg, var(--metric-color, var(--accent)), transparent 90%);
  }
  .metric-card::after {
    content: "";
    position: absolute;
    right: -32px;
    top: -32px;
    width: 96px;
    height: 96px;
    border-radius: 50%;
    background: color-mix(in srgb, var(--metric-color, var(--accent)) 16%, transparent);
    z-index: -1;
  }
  .metric-label {
    color: var(--text-muted);
    font-size: 0.74rem;
    font-weight: 700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }
  .metric-value {
    margin-top: 0.35rem;
    font-size: 1.85rem;
    font-weight: 800;
    letter-spacing: 0;
    line-height: 1.1;
  }
  .metric-subtle {
    margin-top: 0.45rem;
    color: var(--text-muted);
    font-size: 0.8rem;
  }
  .panel { padding: 1.25rem; }
  .panel + .panel { margin-top: 1.25rem; }
  .panel-header {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    align-items: flex-start;
    margin-bottom: 1rem;
  }
  .panel-title {
    margin: 0;
    font-size: 1rem;
    font-weight: 700;
  }
  .panel-kicker {
    margin: 0.2rem 0 0;
    color: var(--text-muted);
    font-size: 0.82rem;
  }
  .chart-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 1.25rem;
    margin-top: 1.25rem;
  }
  .segmented {
    display: flex;
    flex-wrap: wrap;
    gap: 0.45rem;
    margin-bottom: 1rem;
  }
  .segmented a,
  .segmented button {
    min-height: 34px;
    padding: 0.42rem 0.75rem;
    border: 1px solid var(--border);
    border-radius: 7px;
    background: var(--surface-elevated);
    color: var(--text);
    cursor: pointer;
    font: inherit;
    font-size: 0.82rem;
    text-decoration: none;
  }
  .segmented .active,
  .segmented a.active {
    background: var(--accent);
    border-color: var(--accent);
    color: color-mix(in srgb, var(--bg) 88%, #000);
    font-weight: 700;
  }
  .badge {
    display: inline-flex;
    align-items: center;
    min-height: 24px;
    padding: 0.16rem 0.55rem;
    border-radius: 999px;
    background: var(--accent-dim);
    color: var(--text);
    font-size: 0.75rem;
    font-weight: 650;
  }
  .badge.good { background: rgba(34,197,94,0.16); color: var(--green); }
  .badge.bad { background: rgba(239,68,68,0.16); color: var(--red); }
  .muted { color: var(--text-muted); }
  .block-list {
    display: grid;
    gap: 0.9rem;
  }
  .block-card {
    overflow: hidden;
  }
  .block-summary {
    width: 100%;
    padding: 1rem 1.1rem;
    border: 0;
    background: transparent;
    color: inherit;
    cursor: pointer;
    display: grid;
    grid-template-columns: minmax(180px, 1fr) auto;
    gap: 1rem;
    text-align: left;
  }
  .block-summary:hover { background: var(--surface-elevated); }
  .block-date {
    color: var(--text-muted);
    font-size: 0.82rem;
    margin-top: 0.25rem;
  }
  .lift-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(90px, 1fr));
    gap: 0.6rem;
  }
  .lift-mini {
    min-width: 0;
    padding: 0.7rem;
    border: 1px solid var(--border);
    border-radius: 7px;
    background: var(--surface-elevated);
  }
  .lift-mini span {
    display: block;
    color: var(--text-muted);
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
  }
  .lift-mini strong {
    display: block;
    margin-top: 0.25rem;
    font-size: 1rem;
  }
  .block-detail {
    display: none;
    padding: 0 1.1rem 1.1rem;
    border-top: 1px solid var(--border);
  }
  .block-detail.open { display: block; }
  .block-detail-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(130px, 1fr));
    gap: 0.7rem;
    margin: 1rem 0;
  }
  .block-progress {
    padding: 0.8rem;
    border-radius: 7px;
    background: var(--surface-elevated);
  }
  .block-progress-name {
    font-weight: 700;
    margin-bottom: 0.35rem;
  }
  .block-progress-values {
    color: var(--text-muted);
    font-size: 0.82rem;
    margin-bottom: 0.45rem;
  }
  .cycle-row {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 0.35rem;
  }
  .cycle-arrow {
    color: var(--text-muted);
    font-size: 0.75rem;
  }
  .progress-track {
    height: 10px;
    border-radius: 999px;
    background: var(--surface-elevated);
    overflow: hidden;
    margin: 0.2rem 0 0.4rem;
  }
  .progress-fill {
    height: 100%;
    border-radius: 999px;
    background: var(--accent);
  }
  .progress-label {
    display: flex;
    justify-content: space-between;
    color: var(--text-muted);
    font-size: 0.8rem;
  }
  .cycle-timeline {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 0.45rem;
    margin-top: 1.1rem;
  }
  .cycle-step {
    padding: 0.6rem 0.4rem;
    border: 1px solid var(--border);
    border-radius: 8px;
    background: var(--surface-elevated);
    text-align: center;
  }
  .cycle-step.done {
    border-color: var(--accent);
    background: var(--accent-dim);
  }
  .cycle-step.current {
    border-color: var(--accent);
    box-shadow: inset 0 0 0 1px var(--accent);
  }
  .cycle-step-name {
    font-size: 0.76rem;
    font-weight: 700;
  }
  .cycle-step-sub {
    margin-top: 0.2rem;
    color: var(--text-muted);
    font-size: 0.68rem;
  }
  .cycle-step.current .cycle-step-sub {
    color: var(--accent);
    font-weight: 650;
  }
  .week-dots {
    display: flex;
    justify-content: center;
    gap: 0.28rem;
    margin-top: 0.45rem;
  }
  .week-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--text-muted);
    opacity: 0.35;
  }
  .week-dot.done { background: var(--accent); opacity: 1; }
  .week-dot.current {
    background: var(--accent);
    opacity: 1;
    box-shadow: 0 0 0 2px var(--accent-dim);
  }
  .lift-delta { margin-top: 0.3rem; }

  /* Shared page building blocks */
  .crumb { margin-bottom: 1.25rem; font-size: 0.85rem; }
  .crumb a { color: var(--accent); text-decoration: none; }
  .crumb .sep { color: var(--text-muted); margin: 0 0.5rem; }
  .toolbar {
    display: flex;
    gap: 0.75rem;
    margin-bottom: 1.25rem;
    flex-wrap: wrap;
    align-items: center;
  }
  .input, .select {
    height: 42px;
    padding: 0 0.85rem;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 9px;
    color: var(--text);
    font: inherit;
    font-size: 0.9rem;
    outline: none;
  }
  .input:focus, .select:focus {
    border-color: var(--accent);
    box-shadow: 0 0 0 3px var(--accent-dim);
  }
  .input { flex: 1; min-width: 200px; }
  .select { cursor: pointer; }
  .card-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 1rem;
  }
  .ex-card {
    display: block;
    padding: 1.15rem 1.25rem;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
    text-decoration: none;
    color: inherit;
    transition: border-color 0.15s, transform 0.15s;
  }
  .ex-card:hover { border-color: var(--accent); transform: translateY(-2px); }
  .ex-card .ex-name { font-weight: 650; font-size: 0.98rem; margin-bottom: 0.5rem; color: var(--text); }
  .ex-card .ex-meta { display: flex; gap: 1rem; font-size: 0.8rem; color: var(--text-muted); margin-top: 0.5rem; }
  .ex-card .ex-last { font-size: 0.75rem; color: var(--text-muted); margin-top: 0.3rem; }
  .chip {
    display: inline-block;
    padding: 0.16rem 0.55rem;
    background: var(--accent-dim);
    color: var(--accent);
    border-radius: 999px;
    font-size: 0.74rem;
    font-weight: 600;
    white-space: nowrap;
  }
  .chip.neutral { background: var(--surface-elevated); color: var(--text-muted); }
  .workout-row {
    display: flex;
    align-items: center;
    gap: 1rem;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
    padding: 0.9rem 1.1rem;
    margin-bottom: 0.7rem;
    text-decoration: none;
    color: inherit;
    transition: border-color 0.15s, transform 0.15s;
  }
  .workout-row:hover { border-color: var(--accent); transform: translateX(2px); }
  .date-badge { min-width: 52px; text-align: center; }
  .date-badge .month {
    font-size: 0.68rem;
    font-weight: 700;
    color: var(--accent);
    letter-spacing: 0.08em;
  }
  .date-badge .day { font-size: 1.45rem; font-weight: 800; line-height: 1.15; }
  .row-main { flex: 1; min-width: 0; }
  .row-title {
    font-weight: 650;
    font-size: 0.95rem;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .row-sub { font-size: 0.8rem; color: var(--text-muted); margin-top: 0.1rem; }
  .row-chips { display: flex; gap: 0.5rem; flex-shrink: 0; }
  .pagination { display: flex; justify-content: center; gap: 4px; margin-top: 1.5rem; }
  .page-link, .page-gap {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 36px;
    height: 36px;
    border-radius: 8px;
    font-size: 0.85rem;
  }
  .page-link {
    text-decoration: none;
    border: 1px solid var(--border);
    background: var(--surface);
    color: var(--text);
    transition: background 0.15s;
  }
  .page-link:hover { background: var(--surface-elevated); }
  .page-link.active { background: var(--accent); border-color: var(--accent); color: color-mix(in srgb, var(--bg) 88%, #000); font-weight: 750; }
  .page-gap { color: var(--text-muted); }
  .table-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
    overflow: hidden;
    margin-bottom: 1.25rem;
  }
  .table-card .table-title {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin: 0;
    padding: 1rem 1.25rem;
    font-size: 0.95rem;
    font-weight: 650;
    border-bottom: 1px solid var(--border);
  }
  .data-table { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
  .data-table th {
    padding: 0.55rem 1.25rem;
    text-align: left;
    font-size: 0.72rem;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    color: var(--text-muted);
    font-weight: 650;
    background: var(--surface-elevated);
  }
  .data-table td { padding: 0.6rem 1.25rem; border-top: 1px solid var(--border); }
  .data-table tr.best td { background: var(--accent-dim); font-weight: 650; }
  .detail-side .data-table th,
  .detail-side .data-table td {
    padding-left: 0.75rem;
    padding-right: 0.75rem;
  }
  .btn {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    min-height: 36px;
    padding: 0.4rem 0.9rem;
    border: 1px solid var(--border);
    border-radius: 9px;
    background: var(--surface-elevated);
    color: var(--text);
    font: inherit;
    font-size: 0.85rem;
    font-weight: 600;
    cursor: pointer;
    text-decoration: none;
  }
  .btn:hover { background: var(--surface-strong); }
  .btn:disabled { opacity: 0.55; cursor: default; }
  .btn.primary {
    background: var(--accent);
    border-color: transparent;
    color: color-mix(in srgb, var(--bg) 88%, #000);
  }
  .btn.primary:hover { background: var(--accent-hover); transform: translateY(-1px); }
  .btn.danger { background: rgba(239,68,68,0.14); border-color: rgba(239,68,68,0.3); color: var(--red); }
  .btn.danger:hover { background: rgba(239,68,68,0.24); }
  .status-text { font-size: 0.85rem; }
  .status-text.ok { color: var(--green); }
  .status-text.warn { color: var(--amber); }
  .status-text.err { color: var(--red); }
  .scroll-list { max-height: 400px; overflow-y: auto; }
  .list-row {
    padding: 0.75rem 1.25rem;
    border-top: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }
  .list-row .note { font-size: 0.8rem; color: var(--text-muted); font-style: italic; margin-top: 0.15rem; }
  .list-row .value { font-weight: 650; font-size: 0.9rem; white-space: nowrap; }
  .page-head { margin-bottom: 1.5rem; }
  .page-head h2 { margin: 0 0 0.25rem; font-size: clamp(1.55rem, 2vw, 2.2rem); font-weight: 800; letter-spacing: 0; text-wrap: balance; }
  .page-head .meta { color: var(--text-muted); font-size: 0.9rem; }
  .page-head .notes { color: var(--text-muted); font-style: italic; font-size: 0.9rem; margin-top: 0.5rem; }
  .detail-layout {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(280px, 360px);
    gap: 1.25rem;
    align-items: start;
  }
  .detail-main,
  .detail-side {
    min-width: 0;
  }
  .exercise-hero {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: 1rem;
    align-items: end;
    margin-bottom: 1.25rem;
    padding: 1.25rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background:
      radial-gradient(360px 180px at 92% 0%, var(--accent-dim), transparent 72%),
      var(--surface);
    box-shadow: var(--shadow);
  }
  .exercise-hero h2 {
    margin: 0;
    font-size: clamp(1.7rem, 3vw, 3rem);
    line-height: 0.95;
    letter-spacing: 0;
    text-wrap: balance;
  }
  .hero-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 0.45rem;
    margin-top: 0.8rem;
  }
  .hero-stat {
    min-width: 92px;
    padding: 0.7rem 0.8rem;
    border: 1px solid var(--border);
    border-radius: 8px;
    background: color-mix(in srgb, var(--surface-elevated) 80%, transparent);
  }
  .hero-stat span {
    display: block;
    color: var(--text-muted);
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }
  .hero-stat strong {
    display: block;
    margin-top: 0.2rem;
    font-size: 1.08rem;
  }
  .chart-panel { min-height: 360px; }
  .chart-panel canvas { max-height: 420px; }
  .control-row {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 1rem;
  }
  .control-group > span {
    display: block;
    margin-bottom: 0.35rem;
    color: var(--text-muted);
    font-size: 0.72rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }
  .insight-list {
    display: grid;
    gap: 0.75rem;
  }
  .insight-row {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.75rem 0;
    border-top: 1px solid var(--border);
  }
  .insight-row:first-child { border-top: 0; padding-top: 0; }
  .insight-row span { color: var(--text-muted); font-size: 0.82rem; }
  .insight-row strong { font-size: 0.92rem; text-align: right; }
  .history-list {
    display: grid;
    gap: 0.75rem;
  }
  .history-entry {
    display: grid;
    grid-template-columns: 92px minmax(0, 1fr) auto;
    gap: 0.9rem;
    align-items: center;
    padding: 0.9rem 1rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--surface);
    color: inherit;
    text-decoration: none;
    box-shadow: var(--shadow);
  }
  .history-entry:hover { border-color: var(--accent); transform: translateY(-1px); }
  .history-date { color: var(--text-muted); font-size: 0.78rem; }
  .history-title { font-weight: 700; color: var(--text); }
  .history-sub { margin-top: 0.18rem; color: var(--text-muted); font-size: 0.8rem; }
  .history-metrics {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: 0.45rem;
  }

  @media (max-width: 768px) {
    .sidebar { transform: translateX(-100%); }
    .sidebar.open { transform: translateX(0); }
    .main { margin-left: 0; }
    .hamburger { display: block; }
    .overlay.show { display: block; }
    .header { align-items: flex-start; flex-wrap: wrap; }
    .header-actions { width: 100%; justify-content: space-between; }
    .save-picker { flex: 1; }
    .save-picker select { min-width: 0; width: 100%; }
    .content { padding: 1rem; }
    .block-summary { grid-template-columns: 1fr; }
    .lift-grid,
    .block-detail-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .detail-layout,
    .exercise-hero,
    .history-entry { grid-template-columns: 1fr; }
    .history-metrics { justify-content: flex-start; }
  }
</style>
$extraHead
</head>
<body>
<div class="overlay" id="overlay" onclick="toggleSidebar()"></div>
<div class="sidebar" id="sidebar">
  <div class="logo">JackedLog</div>
  <nav>
    ${navItem('Overview', '/dashboard', '<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><rect x="1" y="1" width="6" height="6" rx="1"/><rect x="9" y="1" width="6" height="6" rx="1"/><rect x="1" y="9" width="6" height="6" rx="1"/><rect x="9" y="9" width="6" height="6" rx="1"/></svg>')}
    ${navItem('Exercises', '/dashboard/exercises', '<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M2 4h2v8H2zM12 4h2v8h-2zM5 6h6v4H5z"/></svg>')}
    ${navItem('History', '/dashboard/history', '<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 12.5a5.5 5.5 0 110-11 5.5 5.5 0 010 11zM8.5 4H7v5l4 2.4.75-1.2-3.25-1.95V4z"/></svg>')}
    ${navItem('5/3/1 Blocks', '/dashboard/blocks', '<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M3 1h10v2H3zm0 4h10v2H3zm0 4h10v2H3zm0 4h10v2H3z"/></svg>')}
    ${navItem('Bodyweight', '/dashboard/bodyweight', '<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><circle cx="8" cy="5" r="3"/><path d="M3 14c0-3 2-5 5-5s5 2 5 5z"/></svg>')}
    ${navItem('Backups', '/manage', '<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M2 2h12v3H2zm0 5h12v3H2zm0 5h12v2H2z"/></svg>')}
  </nav>
</div>
<div class="main">
  <div class="header">
    <div class="header-left">
      <button class="hamburger" onclick="toggleSidebar()">&#9776;</button>
      <h1>$title</h1>
    </div>
    <div class="header-actions">
      $savePicker
      <button class="theme-toggle" onclick="toggleTheme()" id="themeBtn" title="Toggle theme">&#9790;</button>
    </div>
  </div>
  <div class="content">
    $content
  </div>
</div>
<script>
function toggleTheme() {
  const html = document.documentElement;
  html.classList.toggle('light');
  const isLight = html.classList.contains('light');
  localStorage.setItem('theme', isLight ? 'light' : 'dark');
  document.getElementById('themeBtn').innerHTML = isLight ? '&#9728;' : '&#9790;';
}
function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('open');
  document.getElementById('overlay').classList.toggle('show');
}
(function() {
  const saved = localStorage.getItem('theme');
  if (saved === 'light') {
    document.documentElement.classList.add('light');
    document.getElementById('themeBtn').innerHTML = '&#9728;';
  }
})();
</script>
$extraScripts
</body>
</html>''';
}

String? _selectedBackup(Request request) {
  final backup = request.url.queryParameters['backup'];
  return backup != null && backup.isNotEmpty ? backup : null;
}

// Auth lives in an HttpOnly cookie, so links never carry the API key.
String _dashboardHref(
  String path,
  String apiKey,
  String? selectedBackup, [
  Map<String, String> params = const {},
]) {
  final query = <String, String>{
    if (selectedBackup != null) 'backup': selectedBackup,
    ...params,
  };
  if (query.isEmpty) return path;
  final queryString = query.entries
      .map((entry) =>
          '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
      .join('&');
  return '$path?$queryString';
}

String _backupHiddenInput(String? selectedBackup) {
  if (selectedBackup == null) return '';
  return '<input type="hidden" name="backup" value="${_escapeHtml(selectedBackup)}">';
}

String _buildSavePicker({
  required String apiKey,
  required String currentPath,
  required Map<String, String> queryParameters,
  required List<BackupInfo> backups,
  required String? selectedBackup,
}) {
  if (backups.isEmpty) return '';

  final hiddenInputs = StringBuffer();
  for (final entry in queryParameters.entries) {
    if (entry.key == 'key' || entry.key == 'backup') continue;
    hiddenInputs.write(
      '<input type="hidden" name="${_escapeHtml(entry.key)}" value="${_escapeHtml(entry.value)}">',
    );
  }

  final options = StringBuffer();
  options.write(
    '<option value=""${selectedBackup == null ? ' selected' : ''}>Latest backup</option>',
  );
  for (final backup in backups) {
    final selected = selectedBackup == backup.filename ? ' selected' : '';
    final version = backup.dbVersion != null ? ' · v${backup.dbVersion}' : '';
    final label =
        '${backup.date.toIso8601String().substring(0, 10)} · ${_formatBytes(backup.sizeBytes)}$version';
    options.write(
      '<option value="${_escapeHtml(backup.filename)}"$selected>${_escapeHtml(label)}</option>',
    );
  }

  return '''
<form class="save-picker" method="GET" action="${_escapeHtml(currentPath)}">
  $hiddenInputs
  <label for="backup-select">Save</label>
  <select id="backup-select" name="backup" onchange="this.form.submit()">
    $options
  </select>
</form>''';
}

/// Format a number with thousands separators.
String _formatNumber(num value) {
  if (value is double) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(1);
  }
  final s = value.toString();
  final result = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
    result.write(s[i]);
  }
  return result.toString();
}

/// Format seconds into human-readable duration.
String _formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Dashboard overview page handler.
Response overviewPageHandler(
  Request request,
  DashboardService dashboardService,
  BackupService backupService,
  String apiKey,
) {
  final selectedBackup = _selectedBackup(request);

  if (!dashboardService.ensureOpen(filename: selectedBackup)) {
    final html = dashboardShell(
      title: 'Overview',
      activeNav: 'Overview',
      content: '''
<div class="empty-state">
  <p>No backup data available</p>
  <p>Upload a backup from the JackedLog app to see your dashboard.</p>
  <a href="/manage">Go to Backup Management</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  final period = request.url.queryParameters['period'];
  final stats = dashboardService.getOverviewStats(period: period);
  final trainingDays = dashboardService.getTrainingDays(period: period);
  final muscleVolumes = dashboardService.getMuscleGroupVolumes(period: period);
  final muscleSets = dashboardService.getMuscleGroupSetCounts(period: period);

  // Build stats cards
  final cardsHtml = '''
<div class="metric-grid">
  <div class="metric-card" style="--metric-color:var(--accent)">
    <div class="metric-label">Workouts</div>
    <div class="metric-value">${_formatNumber(stats['workoutCount'] as int)}</div>
    <div class="metric-subtle">Logged sessions</div>
  </div>
  <div class="metric-card" style="--metric-color:var(--teal)">
    <div class="metric-label">Total Volume</div>
    <div class="metric-value">${_formatNumber(stats['totalVolume'] as double)}</div>
    <div class="metric-subtle">Strength work</div>
  </div>
  <div class="metric-card" style="--metric-color:var(--green)">
    <div class="metric-label">Streak</div>
    <div class="metric-value">${stats['currentStreak']} days</div>
    <div class="metric-subtle">Current run</div>
  </div>
  <div class="metric-card" style="--metric-color:var(--amber)">
    <div class="metric-label">Training Time</div>
    <div class="metric-value">${_formatDuration(stats['totalTimeSeconds'] as int)}</div>
    <div class="metric-subtle">Logged duration</div>
  </div>
</div>''';

  // Build SVG heatmap (GitHub-style)
  final heatmapSvg = _buildHeatmapSvg(trainingDays);

  // Build chart data
  final volumeLabels = muscleVolumes
      .map((m) => "'${_escapeJs(m['muscle'] as String)}'")
      .join(',');
  final volumeData = muscleVolumes
      .map((m) => (m['volume'] as double).toStringAsFixed(1))
      .join(',');
  final setsLabels =
      muscleSets.map((m) => "'${_escapeJs(m['muscle'] as String)}'").join(',');
  final setsData = muscleSets.map((m) => m['sets'].toString()).join(',');

  final chartsHtml = '''
<div class="chart-grid">
  <div class="panel">
    <div class="panel-header">
      <div>
        <h3 class="panel-title">Volume by Muscle Group</h3>
        <p class="panel-kicker">Total lifted weight by category</p>
      </div>
    </div>
    <canvas id="volumeChart"></canvas>
  </div>
  <div class="panel">
    <div class="panel-header">
      <div>
        <h3 class="panel-title">Sets by Muscle Group</h3>
        <p class="panel-kicker">Training density by category</p>
      </div>
    </div>
    <canvas id="setsChart"></canvas>
  </div>
</div>''';

  final content = '''
$cardsHtml
<div class="panel">
  <div class="panel-header">
    <div>
      <h3 class="panel-title">Training Activity</h3>
      <p class="panel-kicker">Set count across the past year</p>
    </div>
  </div>
  <div style="overflow-x:auto">$heatmapSvg</div>
</div>
$chartsHtml''';

  final extraHead =
      '<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>';

  final extraScripts = '''
<script>
(function() {
  const textColor = getComputedStyle(document.documentElement).getPropertyValue('--text-muted').trim() || '#888';
  const gridColor = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#333';
  const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#9fc46d';
  const tealColor = getComputedStyle(document.documentElement).getPropertyValue('--teal').trim() || '#74b6a3';

  const chartOpts = {
    indexAxis: 'y',
    responsive: true,
    maintainAspectRatio: true,
    plugins: { legend: { display: false } },
    scales: {
      x: { ticks: { color: textColor }, grid: { color: gridColor } },
      y: { ticks: { color: textColor }, grid: { display: false } }
    }
  };

  const volCtx = document.getElementById('volumeChart');
  if (volCtx) {
    new Chart(volCtx, {
      type: 'bar',
      data: {
        labels: [$volumeLabels],
        datasets: [{
          data: [$volumeData],
          backgroundColor: 'rgba(159,196,109,0.68)',
          borderColor: accentColor,
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: chartOpts
    });
  }

  const setsCtx = document.getElementById('setsChart');
  if (setsCtx) {
    new Chart(setsCtx, {
      type: 'bar',
      data: {
        labels: [$setsLabels],
        datasets: [{
          data: [$setsData],
          backgroundColor: 'rgba(116,182,163,0.68)',
          borderColor: tealColor,
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: chartOpts
    });
  }
})();
</script>''';

  final html = dashboardShell(
    title: 'Overview',
    activeNav: 'Overview',
    content: content,
    apiKey: apiKey,
    request: request,
    backupService: backupService,
    extraHead: extraHead,
    extraScripts: extraScripts,
  );

  return Response.ok(html, headers: {'content-type': 'text/html'});
}

/// Build a GitHub-style SVG heatmap from training day data.
String _buildHeatmapSvg(Map<String, int> trainingDays) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Go back ~52 weeks
  final startDate = today.subtract(const Duration(days: 363));
  // Align to Monday
  final start = startDate.subtract(Duration(days: startDate.weekday - 1));

  final cellSize = 14;
  final cellGap = 2;
  final cellTotal = cellSize + cellGap;
  final weeks = 53;
  final svgWidth = weeks * cellTotal + 30; // 30 for day labels
  final svgHeight = 7 * cellTotal + 20; // 20 for month labels

  // Find max for color scaling
  final maxSets = trainingDays.values.fold<int>(0, (a, b) => a > b ? a : b);

  final rects = StringBuffer();
  final monthLabels = StringBuffer();
  var lastMonth = -1;

  for (var week = 0; week < weeks; week++) {
    for (var day = 0; day < 7; day++) {
      final date = start.add(Duration(days: week * 7 + day));
      if (date.isAfter(today)) continue;

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final sets = trainingDays[dateStr] ?? 0;
      final x = week * cellTotal + 30;
      final y = day * cellTotal + 20;

      String fill;
      if (sets == 0) {
        fill = 'var(--surface-elevated)';
      } else if (maxSets > 0) {
        final intensity = sets / maxSets;
        if (intensity < 0.25) {
          fill = 'rgba(159,196,109,0.28)';
        } else if (intensity < 0.5) {
          fill = 'rgba(159,196,109,0.46)';
        } else if (intensity < 0.75) {
          fill = 'rgba(159,196,109,0.68)';
        } else {
          fill = 'rgba(159,196,109,1)';
        }
      } else {
        fill = 'var(--surface-elevated)';
      }

      rects.write(
          '<rect x="$x" y="$y" width="$cellSize" height="$cellSize" rx="2" fill="$fill">'
          '<title>$dateStr: $sets sets</title></rect>');

      // Month labels
      if (day == 0 && date.month != lastMonth) {
        lastMonth = date.month;
        const months = [
          '',
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        monthLabels.write(
            '<text x="$x" y="14" fill="var(--text-muted)" font-size="10">'
            '${months[date.month]}</text>');
      }
    }
  }

  // Day-of-week labels
  const dayLabels = ['Mon', '', 'Wed', '', 'Fri', '', 'Sun'];
  final dayLabelsSvg = StringBuffer();
  for (var i = 0; i < 7; i++) {
    if (dayLabels[i].isNotEmpty) {
      final y = i * cellTotal + 20 + 10;
      dayLabelsSvg
          .write('<text x="0" y="$y" fill="var(--text-muted)" font-size="10">'
              '${dayLabels[i]}</text>');
    }
  }

  return '<svg width="$svgWidth" height="$svgHeight" style="font-family:sans-serif">'
      '$dayLabelsSvg$monthLabels$rects</svg>';
}

/// Escape a string for use in JavaScript string literals.
String _escapeJs(String s) => s.replaceAll('\\', '\\\\').replaceAll("'", "\\'");

/// Escape a string for safe use in HTML content and attributes.
String _escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// Exercises list page handler.
Response exercisesPageHandler(
  Request request,
  DashboardService dashboardService,
  BackupService backupService,
  String apiKey,
) {
  final selectedBackup = _selectedBackup(request);

  if (!dashboardService.ensureOpen(filename: selectedBackup)) {
    final html = dashboardShell(
      title: 'Exercises',
      activeNav: 'Exercises',
      content: '''
<div class="empty-state">
  <p>No backup data available</p>
  <p>Upload a backup from the JackedLog app to see your exercises.</p>
  <a href="/manage">Go to Backup Management</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  final search = request.url.queryParameters['search'] ?? '';
  final categoryParam = request.url.queryParameters['category'];
  final category = (categoryParam != null && categoryParam.isNotEmpty)
      ? categoryParam
      : null;

  final categories = dashboardService.getCategories();
  final result = dashboardService.searchExercises(
    search: search,
    category: category,
  );
  final exercises = result['exercises'] as List<Map<String, dynamic>>;

  // Build search/filter bar
  final categoryOptions = StringBuffer();
  categoryOptions.write('<option value="">All Categories</option>');
  for (final cat in categories) {
    final selected = (category == cat) ? ' selected' : '';
    categoryOptions.write(
        '<option value="${_escapeHtml(cat)}"$selected>${_escapeHtml(cat)}</option>');
  }

  final searchBar = '''
<form method="GET" action="/dashboard/exercises" class="toolbar">
  ${_backupHiddenInput(selectedBackup)}
  <input class="input" type="text" name="search" placeholder="Search exercises..." value="${_escapeHtml(search)}">
  <select class="select" name="category" onchange="this.form.submit()">
    $categoryOptions
  </select>
</form>''';

  // Build exercise cards
  String content;
  if (exercises.isEmpty) {
    content = '''
$searchBar
<div class="empty-state">
  <p style="font-size:1.1rem">No exercises found</p>
</div>''';
  } else {
    final cards = StringBuffer();
    for (final ex in exercises) {
      final name = ex['name'] as String;
      final cat = ex['category'] as String? ?? '';
      final workoutCount = ex['workoutCount'] as int;
      final setCount = ex['setCount'] as int;
      final lastUsed = ex['lastUsed'];

      String lastUsedStr = '';
      if (lastUsed != null && lastUsed is int && lastUsed > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(lastUsed * 1000);
        lastUsedStr =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }

      cards.write('''
<a class="ex-card" href="${_dashboardHref('/dashboard/exercise/${Uri.encodeComponent(name)}', apiKey, selectedBackup)}">
  <div class="ex-name">${_escapeHtml(name)}</div>
  ${cat.isNotEmpty ? '<span class="chip">${_escapeHtml(cat)}</span>' : ''}
  <div class="ex-meta">
    <span>$workoutCount workouts</span>
    <span>$setCount sets</span>
  </div>
  ${lastUsedStr.isNotEmpty ? '<div class="ex-last">Last: $lastUsedStr</div>' : ''}
</a>''');
    }

    content = '''
$searchBar
<div class="card-grid">
  $cards
</div>''';
  }

  final html = dashboardShell(
    title: 'Exercises',
    activeNav: 'Exercises',
    content: content,
    apiKey: apiKey,
    request: request,
    backupService: backupService,
  );
  return Response.ok(html, headers: {'content-type': 'text/html'});
}

/// Exercise detail page handler.
Response exerciseDetailHandler(
  Request request,
  String name,
  DashboardService dashboardService,
  BackupService backupService,
  String apiKey,
) {
  final exerciseName = Uri.decodeComponent(name);
  final selectedBackup = _selectedBackup(request);

  if (!dashboardService.ensureOpen(filename: selectedBackup)) {
    final html = dashboardShell(
      title: exerciseName,
      activeNav: 'Exercises',
      content: '''
<div class="empty-state">
  <p>No backup data available</p>
  <p>Upload a backup from the JackedLog app to see exercise details.</p>
  <a href="/manage">Go to Backup Management</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  final metric = request.url.queryParameters['metric'] ?? 'bestWeight';
  final period = request.url.queryParameters['period'] ?? 'all';

  final records = dashboardService.getExerciseRecords(exerciseName);
  final repRecords = dashboardService.getRepRecords(exerciseName);
  final workoutHistory = dashboardService.getExerciseWorkoutHistory(
    exerciseName,
    limit: 24,
  );
  final progress = dashboardService.getExerciseProgress(
    exerciseName,
    metric: metric,
    period: period == 'all' ? null : period,
  );

  // Compute trend line via simple linear regression
  List<Map<String, dynamic>> trendData = [];
  if (progress.length >= 2) {
    final n = progress.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (var i = 0; i < n; i++) {
      final y = (progress[i]['value'] as num).toDouble();
      sumX += i;
      sumY += y;
      sumXY += i * y;
      sumX2 += i * i;
    }
    final denom = n * sumX2 - sumX * sumX;
    if (denom != 0) {
      final m = (n * sumXY - sumX * sumY) / denom;
      final b = (sumY - m * sumX) / n;
      trendData = [
        {
          'created': progress.first['created'],
          'value': b,
        },
        {
          'created': progress.last['created'],
          'value': m * (n - 1) + b,
        },
      ];
    }
  }

  // Breadcrumb
  final breadcrumb = '''
<div class="crumb">
  <a href="${_dashboardHref('/dashboard/exercises', apiKey, selectedBackup)}">Exercises</a>
  <span class="sep">/</span>
  <span>${_escapeHtml(exerciseName)}</span>
</div>''';

  final hasRecords = records['hasRecords'] as bool;
  final recentSetCount = workoutHistory.fold<int>(
    0,
    (sum, item) => sum + (item['setCount'] as int? ?? 0),
  );
  final recentVolume = workoutHistory.fold<double>(
    0,
    (sum, item) => sum + ((item['totalVolume'] as num?)?.toDouble() ?? 0),
  );
  final category = workoutHistory.isNotEmpty
      ? workoutHistory.first['category'] as String?
      : null;
  final unit = workoutHistory.isNotEmpty
      ? workoutHistory.first['unit'] as String?
      : null;

  String hero;
  if (hasRecords) {
    final bestWeight = records['bestWeight'] as double;
    final best1RM = records['best1RM'] as double;
    final bestVolume = records['bestVolume'] as double;
    hero = '''
<section class="exercise-hero">
  <div>
    <h2>${_escapeHtml(exerciseName)}</h2>
    <div class="hero-meta">
      ${category != null && category.isNotEmpty ? '<span class="chip">${_escapeHtml(category)}</span>' : ''}
      ${unit != null && unit.isNotEmpty ? '<span class="chip neutral">${_escapeHtml(unit)}</span>' : ''}
      <span class="chip neutral">${workoutHistory.length} recent workouts</span>
    </div>
  </div>
  <div class="hero-meta">
    <div class="hero-stat"><span>Best weight</span><strong>${_formatNumber(bestWeight)}</strong></div>
    <div class="hero-stat"><span>Est. 1RM</span><strong>${_formatNumber(best1RM)}</strong></div>
    <div class="hero-stat"><span>Best volume</span><strong>${_formatNumber(bestVolume)}</strong></div>
  </div>
</section>''';
  } else {
    hero = '''
<section class="exercise-hero">
  <div>
    <h2>${_escapeHtml(exerciseName)}</h2>
    <div class="hero-meta"><span class="chip neutral">No recorded sets</span></div>
  </div>
</section>
<div class="empty-state">
  <p>No records found for this exercise.</p>
</div>''';
  }

  // Period selector
  const periods = [
    ('week', 'Week'),
    ('month', 'Month'),
    ('3m', '3M'),
    ('6m', '6M'),
    ('year', 'Year'),
    ('all', 'All Time'),
  ];
  final periodButtons = StringBuffer();
  for (final (value, label) in periods) {
    final isActive = value == period;
    periodButtons.write(
        '<a href="${_dashboardHref('/dashboard/exercise/${Uri.encodeComponent(exerciseName)}', apiKey, selectedBackup, {
          'metric': metric,
          'period': value
        })}"'
        '${isActive ? ' class="active"' : ''}>'
        '$label</a>');
  }
  final periodSelector = '''
<div class="segmented">$periodButtons</div>''';

  // Metric selector
  const metrics = [
    ('bestWeight', 'Best Weight'),
    ('oneRepMax', 'Est. 1RM'),
    ('volume', 'Volume'),
  ];
  final metricButtons = StringBuffer();
  for (final (value, label) in metrics) {
    final isActive = value == metric;
    metricButtons.write(
        '<a href="${_dashboardHref('/dashboard/exercise/${Uri.encodeComponent(exerciseName)}', apiKey, selectedBackup, {
          'metric': value,
          'period': period
        })}"'
        '${isActive ? ' class="active"' : ''}>'
        '$label</a>');
  }
  final metricSelector = '''
<div class="segmented">$metricButtons</div>''';
  final metricLabel = switch (metric) {
    'oneRepMax' => 'Est. 1RM',
    'volume' => 'Volume',
    _ => 'Best Weight',
  };

  // Chart section
  String chartSection;
  if (progress.isEmpty) {
    chartSection = '''
<div class="panel chart-panel">
  <div class="control-row">
    <div class="control-group"><span>Range</span>$periodSelector</div>
    <div class="control-group"><span>Metric</span>$metricSelector</div>
  </div>
  <p class="muted" style="text-align:center;margin:1rem 0">No data for this period</p>
</div>''';
  } else {
    // Prepare chart data as JSON
    final progressJson = jsonEncode(progress.map((p) {
      final epoch = p['created'] as int;
      final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
      final workoutId = p['workoutId'];
      return {
        'date':
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
        'value': p['value'],
        'weight': p['weight'],
        'reps': p['reps'],
        'unit': p['unit'],
        'workoutId': workoutId,
        'workoutUrl': workoutId is int
            ? _dashboardHref(
                '/dashboard/workout/$workoutId',
                apiKey,
                selectedBackup,
              )
            : null,
      };
    }).toList());

    final trendJson = jsonEncode(trendData.map((t) {
      final epoch = t['created'] as int;
      final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
      return {
        'date':
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
        'value': t['value'],
      };
    }).toList());

    chartSection = '''
<div class="panel chart-panel">
  <div class="panel-header">
    <div>
      <h3 class="panel-title">$metricLabel progress</h3>
      <p class="panel-kicker">Daily bests; click a point to open the workout</p>
    </div>
  </div>
  <div class="control-row">
    <div class="control-group"><span>Range</span>$periodSelector</div>
    <div class="control-group"><span>Metric</span>$metricSelector</div>
  </div>
  <canvas id="progressChart"></canvas>
</div>
<script type="application/json" id="progress-data">$progressJson</script>
<script type="application/json" id="trend-data">$trendJson</script>''';
  }

  String insightPanel;
  if (workoutHistory.isEmpty) {
    insightPanel = '''
<div class="panel">
  <div class="panel-header">
    <div>
      <h3 class="panel-title">Exercise data</h3>
      <p class="panel-kicker">No recent workout rows found</p>
    </div>
  </div>
</div>''';
  } else {
    final last = workoutHistory.first;
    final lastStart = last['startTime'] as int?;
    final lastDate = lastStart != null ? _formatDate(lastStart) : 'Unknown';
    final bestRecent = workoutHistory.reduce((a, b) {
      final aValue = ((a['bestEstimated1RM'] as num?)?.toDouble() ?? 0);
      final bValue = ((b['bestEstimated1RM'] as num?)?.toDouble() ?? 0);
      return aValue >= bValue ? a : b;
    });
    final bestSet = bestRecent['bestSet'] as Map<String, dynamic>?;
    final bestSetText = bestSet == null
        ? 'n/a'
        : '${_formatNumber(bestSet['weight'] as num)} ${_escapeHtml((bestSet['unit'] ?? '').toString())} x ${_formatNumber(bestSet['reps'] as num)}';
    insightPanel = '''
<div class="panel">
  <div class="panel-header">
    <div>
      <h3 class="panel-title">Exercise data</h3>
      <p class="panel-kicker">Recent workout-level summary</p>
    </div>
  </div>
  <div class="insight-list">
    <div class="insight-row"><span>Last trained</span><strong>$lastDate</strong></div>
    <div class="insight-row"><span>Recent sets</span><strong>$recentSetCount</strong></div>
    <div class="insight-row"><span>Recent volume</span><strong>${_formatVolume(recentVolume)}</strong></div>
    <div class="insight-row"><span>Best recent set</span><strong>$bestSetText</strong></div>
    <div class="insight-row"><span>Best recent est. 1RM</span><strong>${_formatNumber((bestRecent['bestEstimated1RM'] as num?) ?? 0)}</strong></div>
  </div>
</div>''';
  }

  String workoutHistorySection;
  if (workoutHistory.isEmpty) {
    workoutHistorySection = '';
  } else {
    final rows = StringBuffer();
    for (final entry in workoutHistory) {
      final workoutId = entry['workoutId'] as int;
      final startTime = entry['startTime'] as int?;
      final date = startTime != null ? _formatDate(startTime) : 'Unknown';
      final workoutName = entry['workoutName'] as String? ?? 'Workout';
      final setCount = entry['setCount'] as int;
      final totalVolume = (entry['totalVolume'] as num).toDouble();
      final bestWeight = entry['bestWeight'] as double?;
      final best1RM = entry['bestEstimated1RM'] as double?;
      final bestSet = entry['bestSet'] as Map<String, dynamic>?;
      final bestSetText = bestSet == null
          ? 'No best set'
          : '${_formatNumber(bestSet['weight'] as num)} ${_escapeHtml((bestSet['unit'] ?? '').toString())} x ${_formatNumber(bestSet['reps'] as num)}';
      rows.write('''
<a class="history-entry" href="${_dashboardHref('/dashboard/workout/$workoutId', apiKey, selectedBackup)}">
  <div class="history-date">$date</div>
  <div>
    <div class="history-title">${_escapeHtml(workoutName)}</div>
    <div class="history-sub">Best set: $bestSetText</div>
  </div>
  <div class="history-metrics">
    <span class="chip">$setCount sets</span>
    <span class="chip neutral">${_formatVolume(totalVolume)} volume</span>
    ${bestWeight != null ? '<span class="chip neutral">${_formatNumber(bestWeight)} best</span>' : ''}
    ${best1RM != null ? '<span class="chip neutral">${_formatNumber(best1RM)} e1RM</span>' : ''}
  </div>
</a>''');
    }
    workoutHistorySection = '''
<div class="panel" style="margin-top:1.25rem">
  <div class="panel-header">
    <div>
      <h3 class="panel-title">Workout history</h3>
      <p class="panel-kicker">Recent sessions for this exercise, grouped by workout</p>
    </div>
  </div>
  <div class="history-list">$rows</div>
</div>''';
  }

  // Rep records table
  final repRecordsList = repRecords['records'] as List<Map<String, dynamic>>;
  String repTable;
  if (repRecordsList.isEmpty) {
    repTable = '';
  } else {
    final rows = StringBuffer();
    for (final rec in repRecordsList) {
      final reps = rec['repCount'];
      final weight = rec['maxWeight'];
      final unit = rec['unit'] ?? '';
      final created = rec['created'] as int?;
      final workoutId = rec['workoutId'];
      final date = created != null ? _formatDate(created) : '';
      final workoutLink = workoutId is int
          ? _dashboardHref(
              '/dashboard/workout/$workoutId', apiKey, selectedBackup)
          : null;
      rows.write('''
<tr>
  <td>${_formatNumber(reps as num)}</td>
  <td>${_formatNumber(weight as num)} ${_escapeHtml(unit.toString())}</td>
  <td>${_escapeHtml(date)}</td>
  <td>${workoutLink != null ? '<a href="$workoutLink">Open</a>' : ''}</td>
</tr>''');
    }
    repTable = '''
<div class="table-card">
  <h3 class="table-title">Rep Records</h3>
  <table class="data-table">
    <thead>
      <tr><th>Reps</th><th>Best</th><th>Date</th><th>Workout</th></tr>
    </thead>
    <tbody>$rows</tbody>
  </table>
</div>''';
  }

  final content = '''
$breadcrumb
$hero
<div class="detail-layout">
  <div class="detail-main">
    $chartSection
    $workoutHistorySection
  </div>
  <aside class="detail-side">
    $insightPanel
    $repTable
  </aside>
</div>''';

  final extraHead = progress.isNotEmpty
      ? '<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>'
      : '';

  final extraScripts = progress.isNotEmpty
      ? '''
<script>
(function() {
  const progressData = JSON.parse(document.getElementById('progress-data').textContent);
  const trendData = JSON.parse(document.getElementById('trend-data').textContent);
  const gridColor = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#333';
  const textColor = getComputedStyle(document.documentElement).getPropertyValue('--text-muted').trim() || '#888';
  const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#9fc46d';
  const metricLabel = ${jsonEncode(metricLabel)};

  const labels = progressData.map(d => d.date);
  const values = progressData.map(d => d.value);
  const formatValue = value => Number(value).toLocaleString(undefined, {
    maximumFractionDigits: 2
  });

  const datasets = [{
    label: 'Progress',
    data: values,
    borderColor: accentColor,
    borderWidth: 3,
    tension: 0.35,
    pointRadius: 4,
    pointHoverRadius: 7,
    pointHitRadius: 12,
    pointBackgroundColor: accentColor,
    pointBorderColor: getComputedStyle(document.documentElement).getPropertyValue('--surface').trim() || '#11151d',
    pointBorderWidth: 2,
    fill: 'origin',
    backgroundColor: function(context) {
      const chart = context.chart;
      const {ctx, chartArea} = chart;
      if (!chartArea) return 'rgba(159,196,109,0.1)';
      const gradient = ctx.createLinearGradient(0, chartArea.top, 0, chartArea.bottom);
      gradient.addColorStop(0, 'rgba(159,196,109,0.3)');
      gradient.addColorStop(1, 'rgba(159,196,109,0.02)');
      return gradient;
    }
  }];

  if (trendData.length === 2) {
    const trendValues = new Array(labels.length).fill(null);
    trendValues[0] = trendData[0].value;
    trendValues[trendValues.length - 1] = trendData[1].value;
    datasets.push({
      label: 'Trend',
      data: trendValues,
      borderColor: 'rgba(159,196,109,0.5)',
      borderWidth: 2,
      borderDash: [5, 5],
      pointRadius: 0,
      fill: false,
      spanGaps: true
    });
  }

  const ctx = document.getElementById('progressChart');
  if (ctx) {
    new Chart(ctx, {
      type: 'line',
      data: { labels: labels, datasets: datasets },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        interaction: {
          mode: 'nearest',
          intersect: true
        },
        onClick: function(event, elements) {
          if (!elements.length || elements[0].datasetIndex !== 0) return;
          const point = progressData[elements[0].index];
          if (point && point.workoutUrl) {
            window.location.href = point.workoutUrl;
          }
        },
        onHover: function(event, elements) {
          const point = elements.length && elements[0].datasetIndex === 0
            ? progressData[elements[0].index]
            : null;
          event.native.target.style.cursor = point && point.workoutUrl
            ? 'pointer'
            : 'default';
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const point = progressData[context.dataIndex];
                const unit = point.unit ? ' ' + point.unit : '';
                return metricLabel + ': ' + formatValue(point.value) + unit;
              },
              afterLabel: function(context) {
                const point = progressData[context.dataIndex];
                const unit = point.unit ? ' ' + point.unit : '';
                return 'Set: ' + formatValue(point.weight) + unit + ' x ' + formatValue(point.reps);
              },
              footer: function(items) {
                if (!items.length) return '';
                const point = progressData[items[0].dataIndex];
                return point.workoutUrl ? 'Click to open workout' : '';
              }
            }
          }
        },
        scales: {
          x: {
            ticks: { color: textColor, maxTicksLimit: 10 },
            grid: { display: false }
          },
          y: {
            ticks: { color: textColor },
            grid: { color: gridColor }
          }
        }
      }
    });
  }
})();
</script>'''
      : '';

  final html = dashboardShell(
    title: exerciseName,
    activeNav: 'Exercises',
    content: content,
    apiKey: apiKey,
    request: request,
    backupService: backupService,
    extraHead: extraHead,
    extraScripts: extraScripts,
  );
  return Response.ok(html, headers: {'content-type': 'text/html'});
}

/// Format volume with K/M suffix.
String _formatVolume(num value) {
  final v = value.toDouble();
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}

/// History page handler with paginated workout list.
Response historyPageHandler(
  Request request,
  DashboardService dashboardService,
  BackupService backupService,
  String apiKey,
) {
  final selectedBackup = _selectedBackup(request);

  if (!dashboardService.ensureOpen(filename: selectedBackup)) {
    final html = dashboardShell(
      title: 'History',
      activeNav: 'History',
      content: '''
<div class="empty-state">
  <p>No backup data available</p>
  <p>Upload a backup from the JackedLog app to see your workout history.</p>
  <a href="/manage">Go to Backup Management</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  final pageParam = request.url.queryParameters['page'] ?? '1';
  final page = int.tryParse(pageParam) ?? 1;
  const pageSize = 20;

  final result =
      dashboardService.getWorkoutHistory(page: page, pageSize: pageSize);
  final workouts = result['workouts'] as List<Map<String, dynamic>>;
  final totalCount = result['totalCount'] as int;

  String content;

  if (workouts.isEmpty && page == 1) {
    content = '''
<div class="empty-state">
  <p style="font-size:1.1rem">No workouts recorded</p>
</div>''';
  } else {
    const months = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];

    final cards = StringBuffer();
    for (final w in workouts) {
      final startTime = w['startTime'] as int?;
      final endTime = w['endTime'] as int?;
      final name = w['name'] as String? ?? 'Workout';
      final setCount = w['setCount'] as int;
      final totalVolume = w['totalVolume'] as num;
      final workoutId = w['id'] as int;

      // Date parts
      String monthAbbr = '';
      String dayStr = '';
      String timeStr = '';
      String durationStr = '';

      if (startTime != null && startTime > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
        monthAbbr = months[dt.month];
        dayStr = dt.day.toString();
        timeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

        if (endTime != null && endTime > startTime) {
          final durationSecs = endTime - startTime;
          durationStr = _formatDuration(durationSecs);
        }
      }

      final volumeStr = _formatVolume(totalVolume);

      cards.write('''
<a class="workout-row" href="${_dashboardHref('/dashboard/workout/$workoutId', apiKey, selectedBackup)}">
  <div class="date-badge">
    <div class="month">$monthAbbr</div>
    <div class="day">$dayStr</div>
  </div>
  <div class="row-main">
    <div class="row-title">${_escapeHtml(name)}</div>
    <div class="row-sub">$timeStr${durationStr.isNotEmpty ? ' &middot; $durationStr' : ''}</div>
  </div>
  <div class="row-chips">
    <span class="chip">$setCount sets</span>
    <span class="chip neutral">$volumeStr</span>
  </div>
</a>''');
    }

    // Pagination
    final totalPages = totalCount > 0 ? (totalCount / pageSize).ceil() : 1;
    final pagination = StringBuffer();

    if (totalPages > 1) {
      pagination.write('<div class="pagination">');

      // Determine which pages to show
      final pagesToShow = <int>{};
      if (totalPages <= 7) {
        for (var i = 1; i <= totalPages; i++) {
          pagesToShow.add(i);
        }
      } else {
        // Always show first 3 and last 2
        pagesToShow.addAll([1, 2, 3, totalPages - 1, totalPages]);
        // Window around current page
        for (var i = page - 1; i <= page + 1; i++) {
          if (i >= 1 && i <= totalPages) pagesToShow.add(i);
        }
      }

      final sortedPages = pagesToShow.toList()..sort();
      for (var i = 0; i < sortedPages.length; i++) {
        final p = sortedPages[i];

        // Insert ellipsis if gap
        if (i > 0 && p > sortedPages[i - 1] + 1) {
          pagination.write('<span class="page-gap">&hellip;</span>');
        }

        final isActive = p == page;
        pagination.write(
            '<a class="page-link${isActive ? ' active' : ''}" href="${_dashboardHref('/dashboard/history', apiKey, selectedBackup, {
              'page': '$p'
            })}">$p</a>');
      }
      pagination.write('</div>');
    }

    content = '''
<div>$cards</div>
$pagination''';
  }

  final html = dashboardShell(
    title: 'History',
    activeNav: 'History',
    content: content,
    apiKey: apiKey,
    request: request,
    backupService: backupService,
  );
  return Response.ok(html, headers: {'content-type': 'text/html'});
}

/// Workout detail page handler with exercise groups and set tables.
Response workoutDetailHandler(
  Request request,
  String id,
  DashboardService dashboardService,
  BackupService backupService,
  String apiKey,
) {
  final selectedBackup = _selectedBackup(request);
  final workoutId = int.tryParse(id);
  if (workoutId == null) {
    final html = dashboardShell(
      title: 'Not Found',
      activeNav: 'History',
      content: '''
<div class="empty-state">
  <p style="font-size:1.2rem">Invalid workout ID</p>
  <a href="${_dashboardHref('/dashboard/history', apiKey, selectedBackup)}" style="color:var(--accent);text-decoration:none">Back to History</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response(404, body: html, headers: {'content-type': 'text/html'});
  }

  if (!dashboardService.ensureOpen(filename: selectedBackup)) {
    final html = dashboardShell(
      title: 'Workout Detail',
      activeNav: 'History',
      content: '''
<div class="empty-state">
  <p>No backup data available</p>
  <p>Upload a backup from the JackedLog app to see workout details.</p>
  <a href="/manage">Go to Backup Management</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  final detail = dashboardService.getWorkoutDetail(workoutId);
  final workout = detail['workout'] as Map<String, dynamic>?;
  final sets = detail['sets'] as List<Map<String, dynamic>>;

  if (workout == null) {
    final html = dashboardShell(
      title: 'Workout Not Found',
      activeNav: 'History',
      content: '''
<div class="empty-state">
  <p>Workout not found</p>
  <a href="${_dashboardHref('/dashboard/history', apiKey, selectedBackup)}" style="color:var(--accent);text-decoration:none">Back to History</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response(404, body: html, headers: {'content-type': 'text/html'});
  }

  final workoutName = workout['name'] as String? ?? 'Workout';
  final startTime = workout['startTime'] as int?;
  final endTime = workout['endTime'] as int?;
  final notes = workout['notes'] as String?;

  // Format date/time
  String dateStr = '';
  String timeStr = '';
  String durationStr = '';

  if (startTime != null && startTime > 0) {
    final dt = DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    dateStr =
        '${dayNames[dt.weekday - 1]}, ${monthNames[dt.month]} ${dt.day}, ${dt.year}';
    timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (endTime != null && endTime > startTime) {
      durationStr = _formatDuration(endTime - startTime);
    }
  }

  // Back link
  final backLink = '''
<div class="crumb">
  <a href="${_dashboardHref('/dashboard/history', apiKey, selectedBackup)}">&larr; History</a>
</div>''';

  // Workout header
  final header = StringBuffer();
  header.write('<div class="page-head">');
  header.write('<h2>${_escapeHtml(workoutName)}</h2>');
  if (dateStr.isNotEmpty) {
    header.write('<div class="meta">$dateStr');
    if (timeStr.isNotEmpty) header.write(' at $timeStr');
    if (durationStr.isNotEmpty) header.write(' &middot; $durationStr');
    header.write('</div>');
  }
  if (notes != null && notes.isNotEmpty) {
    header.write('<div class="notes">${_escapeHtml(notes)}</div>');
  }
  header.write('</div>');

  // Compute stats
  final exerciseNames = <String>{};
  double totalVolume = 0;
  for (final s in sets) {
    exerciseNames.add(s['name'] as String);
    final weight = (s['weight'] as num?)?.toDouble() ?? 0;
    final reps = (s['reps'] as num?)?.toDouble() ?? 0;
    totalVolume += weight * reps;
  }

  // Stats row
  final statsRow = '''
<div class="metric-grid">
  <div class="metric-card" style="--metric-color:var(--accent)">
    <div class="metric-label">Exercises</div>
    <div class="metric-value">${exerciseNames.length}</div>
  </div>
  <div class="metric-card" style="--metric-color:var(--teal)">
    <div class="metric-label">Sets</div>
    <div class="metric-value">${sets.length}</div>
  </div>
  <div class="metric-card" style="--metric-color:var(--amber)">
    <div class="metric-label">Volume</div>
    <div class="metric-value">${_formatVolume(totalVolume)}</div>
  </div>
</div>''';

  // Group sets by exercise
  String exerciseSections;
  if (sets.isEmpty) {
    exerciseSections = '''
<div class="empty-state">
  <p>No sets recorded for this workout.</p>
</div>''';
  } else {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final categoryByExercise = <String, String>{};
    for (final s in sets) {
      final name = s['name'] as String;
      grouped.putIfAbsent(name, () => []).add(s);
      final cat = s['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        categoryByExercise[name] = cat;
      }
    }

    final sections = StringBuffer();
    for (final entry in grouped.entries) {
      final exerciseName = entry.key;
      final exerciseSets = entry.value;
      final category = categoryByExercise[exerciseName];

      // Find best set (highest weight * reps)
      var bestVolume = 0.0;
      var bestIdx = -1;
      for (var i = 0; i < exerciseSets.length; i++) {
        final w = (exerciseSets[i]['weight'] as num?)?.toDouble() ?? 0;
        final r = (exerciseSets[i]['reps'] as num?)?.toDouble() ?? 0;
        final vol = w * r;
        if (vol > bestVolume) {
          bestVolume = vol;
          bestIdx = i;
        }
      }

      // Check if any set is a warmup or drop set
      var hasSetType = false;
      for (final s in exerciseSets) {
        if (s['warmup'] == true || s['dropSet'] == true) {
          hasSetType = true;
          break;
        }
      }

      sections.write('<div class="table-card">');
      sections.write('<h3 class="table-title">${_escapeHtml(exerciseName)}');
      if (category != null) {
        sections.write(' <span class="chip">${_escapeHtml(category)}</span>');
      }
      sections.write('</h3>');

      // Set table
      sections.write('<table class="data-table">');
      sections.write('<thead><tr><th>Set</th><th>Weight</th><th>Reps</th>');
      if (hasSetType) sections.write('<th>Type</th>');
      sections.write('</tr></thead><tbody>');

      for (var i = 0; i < exerciseSets.length; i++) {
        final s = exerciseSets[i];
        final weight = (s['weight'] as num?)?.toDouble() ?? 0;
        final reps = (s['reps'] as num?)?.toInt() ?? 0;
        final unit = s['unit'] as String? ?? '';
        final isWarmup = s['warmup'] == true;
        final isDropSet = s['dropSet'] == true;
        final isBest = i == bestIdx;

        sections.write('<tr${isBest ? ' class="best"' : ''}>');
        sections.write('<td>${i + 1}</td>');
        sections
            .write('<td>${_formatNumber(weight)} ${_escapeHtml(unit)}</td>');
        sections.write('<td>$reps</td>');
        if (hasSetType) {
          final typeLabel = isWarmup ? 'Warmup' : (isDropSet ? 'Drop Set' : '');
          sections.write('<td class="muted">${_escapeHtml(typeLabel)}</td>');
        }
        sections.write('</tr>');
      }

      sections.write('</tbody></table>');
      sections.write('</div>');
    }
    exerciseSections = sections.toString();
  }

  final content = '''
$backLink
${header.toString()}
$statsRow
$exerciseSections''';

  final html = dashboardShell(
    title: _escapeHtml(workoutName),
    activeNav: 'History',
    content: content,
    apiKey: apiKey,
    request: request,
    backupService: backupService,
  );
  return Response.ok(html, headers: {'content-type': 'text/html'});
}

/// Format epoch seconds to "MMM D, YYYY" date string.
String _formatDate(int epochSeconds) {
  final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month]} ${dt.day}, ${dt.year}';
}

/// 5/3/1 Blocks history page handler.
Response blockHistoryPageHandler(
  Request request,
  DashboardService dashboardService,
  BackupService backupService,
  String apiKey,
) {
  final selectedBackup = _selectedBackup(request);

  if (!dashboardService.ensureOpen(filename: selectedBackup)) {
    final html = dashboardShell(
      title: '5/3/1 Blocks',
      activeNav: '5/3/1 Blocks',
      content: '''
<div class="empty-state">
  <p>No backup data available</p>
  <p>Upload a backup from the JackedLog app to see your 5/3/1 blocks.</p>
  <a href="/manage">Go to Backup Management</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  final activeBlock = dashboardService.getActiveBlock();
  final blocks = dashboardService.getCompletedBlocks();

  if (activeBlock == null && blocks.isEmpty) {
    final html = dashboardShell(
      title: '5/3/1 Blocks',
      activeNav: '5/3/1 Blocks',
      content: '''
<div class="empty-state">
  <p>No 5/3/1 data</p>
  <p>Start a 5/3/1 block in the app and push a backup to see it here.</p>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  // Cycle names from schemes.dart
  const cycleNames = [
    'Leader 1',
    'Leader 2',
    '7th Week Protocol',
    'Anchor',
    '7th Week Protocol'
  ];
  // Weeks per cycle and main-work scheme labels (mirrors lib/.../schemes.dart).
  const cycleWeeks = [3, 3, 1, 3, 1];
  const schemeNames = ["5's PRO", "5's PRO", 'Deload', 'PR Sets', 'TM Test'];
  const totalBlockWeeks = 11; // 3 + 3 + 1 + 3 + 1

  String deltaBadge(double delta) {
    if (delta > 0) {
      return '<span class="badge good">+${delta.toStringAsFixed(1)}</span>';
    } else if (delta < 0) {
      return '<span class="badge bad">${delta.toStringAsFixed(1)}</span>';
    }
    return '<span class="badge muted">0</span>';
  }

  // --- Current block panel (top of page) ---
  final currentSection = StringBuffer();
  if (activeBlock == null) {
    currentSection.write('''
<div class="panel">
  <div class="panel-header">
    <div>
      <h2 class="panel-title">Current Block</h2>
      <p class="panel-kicker">No active block right now. Start one in the app.</p>
    </div>
  </div>
</div>''');
  } else {
    final unit = activeBlock['unit'] as String;
    final created = activeBlock['created'] as int;
    final cc = (activeBlock['currentCycle'] as int).clamp(0, 4);
    final cw = (activeBlock['currentWeek'] as int).clamp(1, cycleWeeks[cc]);

    var weeksDone = 0;
    for (var c = 0; c < cc; c++) {
      weeksDone += cycleWeeks[c];
    }
    weeksDone += cw - 1;
    final overallWeek = weeksDone + 1;
    final pct = ((weeksDone / totalBlockWeeks) * 100).round();

    // Cycle timeline (5 steps, current one shows week dots)
    final timeline = StringBuffer();
    for (var c = 0; c < cycleNames.length; c++) {
      final stateClass = c < cc ? 'done' : (c == cc ? 'current' : '');
      final dots = StringBuffer();
      if (c == cc) {
        for (var w = 1; w <= cycleWeeks[c]; w++) {
          final wc = w < cw ? 'done' : (w == cw ? 'current' : '');
          dots.write('<div class="week-dot $wc"></div>');
        }
      }
      timeline.write('''
<div class="cycle-step $stateClass">
  <div class="cycle-step-name">${cycleNames[c]}</div>
  <div class="cycle-step-sub">${schemeNames[c]}</div>
  ${c == cc ? '<div class="week-dots">$dots</div>' : ''}
</div>''');
    }

    String currentLift(String name, double start, double current) {
      final delta = current - start;
      final badge = delta != 0
          ? '<div class="lift-delta">${deltaBadge(delta)}</div>'
          : '';
      return '''
<div class="lift-mini">
  <span>$name</span>
  <strong>${current.toStringAsFixed(1)} $unit</strong>
  $badge
</div>''';
    }

    currentSection.write('''
<div class="panel">
  <div class="panel-header">
    <div>
      <h2 class="panel-title">Current Block</h2>
      <p class="panel-kicker">${cycleNames[cc]} &middot; ${schemeNames[cc]} &mdash; Week $cw of ${cycleWeeks[cc]}</p>
    </div>
    <span class="badge">Week $overallWeek / $totalBlockWeeks</span>
  </div>
  <div class="progress-track"><div class="progress-fill" style="width:$pct%"></div></div>
  <div class="progress-label">
    <span>Started ${_formatDate(created)}</span>
    <span>$pct% complete</span>
  </div>
  <div class="cycle-timeline">$timeline</div>
  <div class="lift-grid" style="margin-top:1.1rem">
    ${currentLift('Squat', activeBlock['startSquatTm'] as double, activeBlock['squatTm'] as double)}
    ${currentLift('Bench', activeBlock['startBenchTm'] as double, activeBlock['benchTm'] as double)}
    ${currentLift('Deadlift', activeBlock['startDeadliftTm'] as double, activeBlock['deadliftTm'] as double)}
    ${currentLift('OHP', activeBlock['startPressTm'] as double, activeBlock['pressTm'] as double)}
  </div>
</div>''');
  }

  // Build block cards
  final cardsHtml = StringBuffer();
  for (var i = 0; i < blocks.length; i++) {
    final block = blocks[i];
    final created = block['created'] as int;
    final completed = block['completed'] as int;
    final unit = block['unit'] as String;
    final squatTm = block['squatTm'] as double;
    final benchTm = block['benchTm'] as double;
    final deadliftTm = block['deadliftTm'] as double;
    final pressTm = block['pressTm'] as double;
    final startSquatTm = block['startSquatTm'] as double;
    final startBenchTm = block['startBenchTm'] as double;
    final startDeadliftTm = block['startDeadliftTm'] as double;
    final startPressTm = block['startPressTm'] as double;

    final dateRange = '${_formatDate(created)} - ${_formatDate(completed)}';

    String liftSummary(String name, double value) {
      return '''
<div class="lift-mini">
  <span>$name</span>
  <strong>${value.toStringAsFixed(1)}</strong>
</div>''';
    }

    String liftProgress(String name, double start, double end) {
      final delta = end - start;
      return '''
<div class="block-progress">
  <div class="block-progress-name">$name</div>
  <div class="block-progress-values">${start.toStringAsFixed(1)} &rarr; ${end.toStringAsFixed(1)} $unit</div>
  ${deltaBadge(delta)}
</div>''';
    }

    // Cycle structure labels
    final cycleBadges = StringBuffer();
    for (var c = 0; c < cycleNames.length; c++) {
      if (c > 0) {
        cycleBadges.write('<span class="cycle-arrow">&rarr;</span>');
      }
      cycleBadges.write('<span class="badge">${cycleNames[c]}</span>');
    }

    final totalDelta = (squatTm - startSquatTm) +
        (benchTm - startBenchTm) +
        (deadliftTm - startDeadliftTm) +
        (pressTm - startPressTm);
    final totalDeltaBadge = deltaBadge(totalDelta);

    cardsHtml.write('''
<div class="block-card">
  <button type="button" class="block-summary" onclick="toggleBlock($i)">
    <div>
      <div style="display:flex;align-items:center;gap:0.5rem;flex-wrap:wrap">
        <strong>Completed block</strong>
        $totalDeltaBadge
        <span id="arrow-$i" class="muted" style="transition:transform 0.2s">&#9660;</span>
      </div>
      <div class="block-date">$dateRange</div>
    </div>
    <div class="lift-grid">
      ${liftSummary('Squat', squatTm)}
      ${liftSummary('Bench', benchTm)}
      ${liftSummary('Deadlift', deadliftTm)}
      ${liftSummary('OHP', pressTm)}
    </div>
  </button>
  <div id="detail-$i" class="block-detail">
    <div class="block-detail-grid">
      ${liftProgress('Squat', startSquatTm, squatTm)}
      ${liftProgress('Bench', startBenchTm, benchTm)}
      ${liftProgress('Deadlift', startDeadliftTm, deadliftTm)}
      ${liftProgress('OHP', startPressTm, pressTm)}
    </div>
    <div class="cycle-row">$cycleBadges</div>
  </div>
</div>''');
  }

  // TM progression chart + finished-blocks list (only when completed blocks
  // exist). The chart is the long-term, block-to-block view so it sits under
  // the current-block panel.
  final hasBlocks = blocks.isNotEmpty;
  var chartSection = '';
  var finishedSection = '';

  if (hasBlocks) {
    final chartBlocks = blocks.length > 10 ? blocks.sublist(0, 10) : blocks;
    final chartReversed = chartBlocks.reversed.toList();
    final chartLabels =
        List.generate(chartReversed.length, (i) => 'Block ${i + 1}');

    final chartDataJson = jsonEncode({
      'labels': chartLabels,
      'squat': chartReversed.map((b) => b['squatTm']).toList(),
      'bench': chartReversed.map((b) => b['benchTm']).toList(),
      'deadlift': chartReversed.map((b) => b['deadliftTm']).toList(),
      'press': chartReversed.map((b) => b['pressTm']).toList(),
    });

    final limitNote = blocks.length > 10
        ? '<p style="font-size:0.8rem;color:var(--text-muted);margin-top:0.5rem">Showing last 10 blocks</p>'
        : '';

    chartSection = '''
<div class="panel" style="margin-top:1.25rem">
  <div class="panel-header">
    <div>
      <h3 class="panel-title">TM Progression</h3>
      <p class="panel-kicker">Training max changes across completed blocks (long term)</p>
    </div>
  </div>
  <canvas id="tmChart"></canvas>
  $limitNote
</div>
<script type="application/json" id="blocks-data">$chartDataJson</script>''';

    finishedSection = '''
<div class="panel-header" style="margin-top:1.25rem">
  <div>
    <h2 class="panel-title">Finished Blocks</h2>
    <p class="panel-kicker">${blocks.length} completed 5/3/1 block${blocks.length == 1 ? '' : 's'}</p>
  </div>
</div>
<div class="block-list">$cardsHtml</div>''';
  }

  // Order: current block progress, then long-term TM progression, then history.
  final content = '''
$currentSection
$chartSection
$finishedSection''';

  final extraHead = hasBlocks
      ? '<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>'
      : '';

  final chartScript = hasBlocks
      ? '''
(function() {
  const data = JSON.parse(document.getElementById('blocks-data').textContent);
  const textColor = getComputedStyle(document.documentElement).getPropertyValue('--text-muted').trim() || '#888';
  const gridColor = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#333';

  const ctx = document.getElementById('tmChart');
  if (ctx) {
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: [
          { label: 'Squat', data: data.squat, borderColor: '#ef4444', backgroundColor: 'rgba(239,68,68,0.12)', borderWidth: 3, tension: 0.28, pointRadius: 4 },
          { label: 'Bench', data: data.bench, borderColor: '#3b82f6', backgroundColor: 'rgba(59,130,246,0.12)', borderWidth: 3, tension: 0.28, pointRadius: 4 },
          { label: 'Deadlift', data: data.deadlift, borderColor: '#22c55e', backgroundColor: 'rgba(34,197,94,0.12)', borderWidth: 3, tension: 0.28, pointRadius: 4 },
          { label: 'OHP', data: data.press, borderColor: '#f59e0b', backgroundColor: 'rgba(245,158,11,0.12)', borderWidth: 3, tension: 0.28, pointRadius: 4 }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            labels: { color: textColor }
          }
        },
        scales: {
          x: { ticks: { color: textColor }, grid: { display: false } },
          y: { beginAtZero: false, ticks: { color: textColor }, grid: { color: gridColor } }
        }
      }
    });
  }
})();
'''
      : '';

  final extraScripts = '''
<script>
function toggleBlock(id) {
  const detail = document.getElementById('detail-' + id);
  const arrow = document.getElementById('arrow-' + id);
  const isHidden = !detail.classList.contains('open');
  detail.classList.toggle('open', isHidden);
  arrow.style.transform = isHidden ? 'rotate(180deg)' : '';
}
$chartScript
</script>''';

  final html = dashboardShell(
    title: '5/3/1 Blocks',
    activeNav: '5/3/1 Blocks',
    content: content,
    apiKey: apiKey,
    request: request,
    backupService: backupService,
    extraHead: extraHead,
    extraScripts: extraScripts,
  );
  return Response.ok(html, headers: {'content-type': 'text/html'});
}

/// Bodyweight tracking page handler.
Response bodyweightPageHandler(
  Request request,
  DashboardService dashboardService,
  BackupService backupService,
  String apiKey,
) {
  final selectedBackup = _selectedBackup(request);

  if (!dashboardService.ensureOpen(filename: selectedBackup)) {
    final html = dashboardShell(
      title: 'Bodyweight',
      activeNav: 'Bodyweight',
      content: '''
<div class="empty-state">
  <p>No backup data available</p>
  <p>Upload a backup from the JackedLog app to see your bodyweight data.</p>
  <a href="/manage">Go to Backup Management</a>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  final period = request.url.queryParameters['period'] ?? 'all';
  final data = dashboardService.getBodyweightData(
    period: period == 'all' ? null : period,
  );
  final entries = data['entries'] as List<Map<String, dynamic>>;
  final stats = data['stats'] as Map<String, dynamic>;

  if (entries.isEmpty) {
    final html = dashboardShell(
      title: 'Bodyweight',
      activeNav: 'Bodyweight',
      content: '''
<div class="empty-state">
  <p>No bodyweight data</p>
  <p>Log bodyweight entries in the app and push a backup to see your tracking data.</p>
</div>''',
      apiKey: apiKey,
      request: request,
      backupService: backupService,
    );
    return Response.ok(html, headers: {'content-type': 'text/html'});
  }

  final ma3 = data['ma3'] as List<double?>;
  final ma7 = data['ma7'] as List<double?>;
  final ma14 = data['ma14'] as List<double?>;

  // Period selector
  const periods = [
    ('7d', '7D'),
    ('1m', '1M'),
    ('3m', '3M'),
    ('6m', '6M'),
    ('1y', '1Y'),
    ('all', 'All'),
  ];
  final periodButtons = StringBuffer();
  for (final (value, label) in periods) {
    final isActive = value == period;
    periodButtons.write(
        '<a href="${_dashboardHref('/dashboard/bodyweight', apiKey, selectedBackup, {
          'period': value
        })}"'
        ' class="${isActive ? 'active' : ''}">'
        '$label</a>');
  }
  final periodSelector = '''
<div class="segmented">$periodButtons</div>''';

  // Stats cards
  final unit = stats['unit'] as String;
  final current = stats['current'] as double;
  final average = stats['average'] as double;
  final change = stats['change'] as double?;
  final entryCount = stats['entries'] as int;

  String changeStr;
  if (change != null) {
    final prefix = change >= 0 ? '+' : '';
    changeStr = '$prefix${change.toStringAsFixed(1)} $unit';
  } else {
    changeStr = '--';
  }

  final cardsHtml = '''
<div class="metric-grid">
  <div class="metric-card" style="--metric-color:var(--accent)">
    <div class="metric-label">Current</div>
    <div class="metric-value">${current.toStringAsFixed(1)} $unit</div>
    <div class="metric-subtle">Latest entry</div>
  </div>
  <div class="metric-card" style="--metric-color:var(--teal)">
    <div class="metric-label">Average</div>
    <div class="metric-value">${average.toStringAsFixed(1)} $unit</div>
    <div class="metric-subtle">Selected range</div>
  </div>
  <div class="metric-card" style="--metric-color:${change != null && change < 0 ? 'var(--green)' : 'var(--amber)'}">
    <div class="metric-label">Change</div>
    <div class="metric-value">$changeStr</div>
    <div class="metric-subtle">First to latest</div>
  </div>
  <div class="metric-card" style="--metric-color:var(--green)">
    <div class="metric-label">Entries</div>
    <div class="metric-value">$entryCount</div>
    <div class="metric-subtle">Measurements</div>
  </div>
</div>''';

  // MA toggle buttons
  final maToggles = '''
<div class="segmented">
  <button id="ma-btn-1" onclick="toggleMA(1)">14-Day MA</button>
  <button id="ma-btn-2" onclick="toggleMA(2)">7-Day MA</button>
  <button id="ma-btn-3" onclick="toggleMA(3)">3-Day MA</button>
</div>''';

  // Chart data
  final chartDates = <String>[];
  final chartWeights = <double>[];
  for (final entry in entries) {
    final epoch = entry['date'] as int;
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    chartDates.add('${months[dt.month]} ${dt.day}');
    chartWeights.add(entry['weight'] as double);
  }

  final chartDataJson = jsonEncode({
    'dates': chartDates,
    'weights': chartWeights,
    'ma3': ma3,
    'ma7': ma7,
    'ma14': ma14,
  });

  final chartSection = '''
<div class="panel" style="margin-bottom:1.25rem">
  <div class="panel-header">
    <div>
      <h3 class="panel-title">Bodyweight Trend</h3>
      <p class="panel-kicker">Raw entries with optional moving averages</p>
    </div>
  </div>
  <canvas id="bodyweightChart"></canvas>
</div>
<script type="application/json" id="bw-data">$chartDataJson</script>''';

  // Entry history list (most recent first)
  final historyEntries = entries.reversed.toList();
  final historyHtml = StringBuffer();
  historyHtml.write('<div class="table-card">');
  historyHtml.write('<h3 class="table-title">Entry History</h3>');
  historyHtml.write('<div class="scroll-list">');
  for (final entry in historyEntries) {
    final epoch = entry['date'] as int;
    final weight = entry['weight'] as double;
    final entryUnit = entry['unit'] as String;
    final notes = entry['notes'] as String?;

    final dateStr = _formatDate(epoch);

    historyHtml.write('<div class="list-row">');
    historyHtml.write('<div><span>${_escapeHtml(dateStr)}</span>');
    if (notes != null && notes.isNotEmpty) {
      historyHtml.write('<div class="note">${_escapeHtml(notes)}</div>');
    }
    historyHtml.write('</div>');
    historyHtml.write(
        '<span class="value">${weight.toStringAsFixed(1)} $entryUnit</span>');
    historyHtml.write('</div>');
  }
  historyHtml.write('</div></div>');

  final content = '''
$periodSelector
$cardsHtml
$maToggles
$chartSection
$historyHtml''';

  final extraHead =
      '<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>';

  final extraScripts = '''
<script>
var bwChart;
(function() {
  const data = JSON.parse(document.getElementById('bw-data').textContent);
  const gridColor = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#333';
  const textColor = getComputedStyle(document.documentElement).getPropertyValue('--text-muted').trim() || '#888';
  const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#9fc46d';
  const tealColor = getComputedStyle(document.documentElement).getPropertyValue('--teal').trim() || '#74b6a3';
  const amberColor = getComputedStyle(document.documentElement).getPropertyValue('--amber').trim() || '#d6a15d';

  const ctx = document.getElementById('bodyweightChart');
  if (ctx) {
    bwChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.dates,
        datasets: [
          {
            label: 'Bodyweight',
            data: data.weights,
            borderColor: accentColor,
            borderWidth: 3,
            tension: 0.35,
            pointRadius: 4,
            pointBackgroundColor: accentColor,
            fill: 'origin',
            backgroundColor: function(context) {
              const chart = context.chart;
              const {ctx, chartArea} = chart;
              if (!chartArea) return 'rgba(159,196,109,0.1)';
              const gradient = ctx.createLinearGradient(0, chartArea.top, 0, chartArea.bottom);
              gradient.addColorStop(0, 'rgba(159,196,109,0.3)');
              gradient.addColorStop(1, 'rgba(159,196,109,0.02)');
              return gradient;
            }
          },
          {
            label: '14-Day MA',
            data: data.ma14,
            borderColor: tealColor,
            borderDash: [5, 5],
            borderWidth: 2,
            pointRadius: 0,
            fill: false,
            hidden: true,
            spanGaps: true
          },
          {
            label: '7-Day MA',
            data: data.ma7,
            borderColor: accentColor,
            borderDash: [5, 5],
            borderWidth: 2,
            pointRadius: 0,
            fill: false,
            hidden: true,
            spanGaps: true
          },
          {
            label: '3-Day MA',
            data: data.ma3,
            borderColor: amberColor,
            borderDash: [5, 5],
            borderWidth: 2,
            pointRadius: 0,
            fill: false,
            hidden: true,
            spanGaps: true
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: { legend: { display: false } },
        scales: {
          x: {
            ticks: { color: textColor, maxTicksLimit: 8 },
            grid: { display: false }
          },
          y: {
            ticks: { color: textColor },
            grid: { color: gridColor }
          }
        }
      }
    });
  }
})();

function toggleMA(datasetIndex) {
  if (!bwChart) return;
  const meta = bwChart.getDatasetMeta(datasetIndex);
  const isHidden = !meta.hidden;
  bwChart.setDatasetVisibility(datasetIndex, !isHidden);
  bwChart.update();

  const styles = getComputedStyle(document.documentElement);
  const colors = {
    1: styles.getPropertyValue('--teal').trim() || '#74b6a3',
    2: styles.getPropertyValue('--accent').trim() || '#9fc46d',
    3: styles.getPropertyValue('--amber').trim() || '#d6a15d'
  };
  const btn = document.getElementById('ma-btn-' + datasetIndex);
  if (btn) {
    btn.classList.toggle('active', !isHidden);
    btn.style.borderColor = !isHidden ? colors[datasetIndex] : '';
  }
}
</script>''';

  final html = dashboardShell(
    title: 'Bodyweight',
    activeNav: 'Bodyweight',
    content: content,
    apiKey: apiKey,
    request: request,
    backupService: backupService,
    extraHead: extraHead,
    extraScripts: extraScripts,
  );
  return Response.ok(html, headers: {'content-type': 'text/html'});
}
