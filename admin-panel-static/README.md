# SMARTFARMING Admin Panel (Static)

This is a **standalone static version** of the admin web panel. It runs in any modern browser without a backend or build step.

## How to run

1. Open `index.html` in a browser (double-click or drag into the window), or
2. Serve the folder with any static server, for example:
   - `npx serve .`
   - `python -m http.server 8080` (then open http://localhost:8080)
   - Open from VS Code with "Live Server" if installed.

## Contents

- **index.html** – Single-page app: splash, login, dashboard, farmer management, detection records, model trainer, profile, calendar, soil & weather.
- **styles.css** – All styles (theme, layout, components). Uses Google Fonts (Roboto, Material Symbols).
- **app.js** – Routing, forms, modals, mock data, and client-side behavior.
- **assets/** – Optional. Place `bg.png` here to use the same background image as the Flutter app on login/dashboard. If absent, the primary green color is used.

## Design and behavior

- Layout, colors, fonts, spacing, and responsiveness match the Flutter admin theme (#41644A primary, #e8f5e9 scaffold, white cards, Roboto).
- All existing admin features are preserved: login, dashboard with quick actions and stats, farmer list with menu (edit/delete), detection records, model trainer (file pickers and actions), profile, treatment calendar with filters and actions, soil & weather.
- No Firebase or backend: login is simulated (any email/password), and data is mock. Ready for later wiring to a real API if needed.

## Notes

- Icons use [Material Symbols Outlined](https://fonts.google.com/icons) (loaded from Google Fonts).
- Scripts and styles are linked with relative paths so the panel works when opened from the file system or from a server.
