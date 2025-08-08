# USAi Keycloak Theme

This is a custom Keycloak theme designed to match the USAi (US Government AI) design system, featuring:

## Features

- **US Government Banner**: Official government website banner at the top
- **USAi Branding**: Black header with USAi logo
- **Agency Selection**: Login page designed for agency credential selection
- **Responsive Design**: Mobile-friendly layout
- **Accessibility**: WCAG compliant design elements
- **Government Footer**: Links to various government resources

## Files Structure

```
usai/
├── login/
│   ├── theme.properties          # Theme configuration
│   ├── template.ftl             # Main page template
│   ├── login.ftl                # Login form template
│   ├── footer.ftl               # Footer template
│   └── resources/
│       ├── css/
│       │   └── usai.css         # Custom USAi styles
│       └── img/
│           └── us_flag_small.svg # US flag icon
└── README.md                    # This file
```

## Usage

1. Deploy this theme to your Keycloak instance
2. In the Keycloak admin console, go to Realm Settings > Themes
3. Set the Login Theme to "usai"
4. Configure identity providers (social providers) to represent different agencies:
   - General Services Administration
   - Department of Education
   - Department of Labor
   - NIST
   - CISA
   - etc.

## Customization

The theme is designed to work with Keycloak's identity provider system. Each agency should be configured as a separate identity provider, and they will automatically appear as buttons in the agency selection interface.

## Design System

The theme follows US Web Design System (USWDS) principles:
- Typography: Source Sans Pro font family
- Colors: Government blue (#0066cc), black header, light gray background
- Components: Cards, buttons, alerts following USWDS patterns
- Layout: Responsive grid system

## Browser Support

- Chrome/Chromium 60+
- Firefox 60+
- Safari 12+
- Edge 79+
