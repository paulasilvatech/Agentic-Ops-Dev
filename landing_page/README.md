# Agentic Operations Landing Page

This is the landing page for the Agentic Operations Workshop, built with React, TypeScript, and Tailwind CSS.

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ installed
- npm or yarn package manager

### Development

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

3. Open [http://localhost:5173](http://localhost:5173) in your browser

### Building for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

### Local Preview

To preview the production build locally:

```bash
npm run preview
```

## 🌐 Deployment

The landing page is automatically deployed to GitHub Pages when changes are pushed to the `main` branch.

### Manual Deployment

If you need to deploy manually:

```bash
npm run deploy
```

### GitHub Pages Setup

1. Go to your repository settings
2. Navigate to Pages section
3. Under "Build and deployment", select "GitHub Actions" as the source
4. The workflow will automatically deploy on push to main branch

## 📁 Project Structure

```
landing_page/
├── src/
│   ├── App.tsx          # Main app component
│   ├── LandingPage.tsx  # Landing page component
│   ├── main.tsx         # Entry point
│   └── index.css        # Global styles with Tailwind
├── index.html           # HTML template
├── package.json         # Dependencies and scripts
├── vite.config.ts       # Vite configuration
├── tailwind.config.js   # Tailwind CSS configuration
└── tsconfig.json        # TypeScript configuration
```

## 🎨 Customization

### Colors

The landing page uses an orange/red gradient theme. To customize colors, edit the Tailwind classes in `LandingPage.tsx`.

### Content

All content is in the `LandingPage.tsx` file. Update the following arrays to modify content:
- `modules` - Workshop modules
- `benefits` - Business impact metrics
- `maturityStages` - Observability maturity stages
- `prerequisites` - Required tools and knowledge
- `keyFeatures` - Key features of the workshop

### Animations

The blob animations are defined in `tailwind.config.js`. You can adjust the animation timing and keyframes there.

## 🔧 Technologies

- **React** - UI framework
- **TypeScript** - Type safety
- **Tailwind CSS** - Utility-first CSS framework
- **Vite** - Build tool and dev server
- **Lucide React** - Icon library

## 📝 License

This project is part of the Agentic-Ops-Dev repository and follows the same MIT license. 