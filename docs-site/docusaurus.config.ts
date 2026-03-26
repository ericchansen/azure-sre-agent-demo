import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Azure SRE Agent Demo',
  tagline: 'AI-powered incident detection and remediation — live.',
  favicon: 'img/favicon.svg',

  future: {
    v4: true,
  },

  url: 'https://ericchansen.github.io',
  baseUrl: '/azure-sre-agent-demo/',

  organizationName: 'ericchansen',
  projectName: 'azure-sre-agent-demo',

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl:
            'https://github.com/ericchansen/azure-sre-agent-demo/edit/main/docs-site/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/logo.svg',
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Azure SRE Agent Demo',
      logo: {
        alt: 'Azure SRE Agent',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: 'https://sre.azure.com/docs/',
          label: 'SRE Agent Docs',
          position: 'left',
        },
        {
          href: 'https://github.com/ericchansen/azure-sre-agent-demo',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'This Demo',
          items: [
            {label: 'Overview', to: '/docs/overview'},
            {label: 'Demo Script', to: '/docs/demo-script'},
            {label: 'Architecture', to: '/docs/architecture'},
          ],
        },
        {
          title: 'Azure SRE Agent',
          items: [
            {label: 'Product Overview', href: 'https://sre.azure.com/docs/overview'},
            {label: 'Get Started', href: 'https://sre.azure.com/docs/get-started/create-and-setup'},
            {label: 'Incident Response', href: 'https://sre.azure.com/docs/capabilities/incident-response'},
            {label: 'Run Modes', href: 'https://sre.azure.com/docs/concepts/run-modes'},
          ],
        },
        {
          title: 'Repos',
          items: [
            {label: 'Demo (this repo)', href: 'https://github.com/ericchansen/azure-sre-agent-demo'},
            {label: 'Webstore App', href: 'https://github.com/ericchansen/webstore'},
            {label: 'Official Bicep Samples', href: 'https://github.com/microsoft/sre-agent'},
          ],
        },
      ],
      copyright: `Built for AIOps talks. Powered by <a href="https://sre.azure.com/docs/" target="_blank" rel="noopener noreferrer">Azure SRE Agent</a>.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'bicep', 'json'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
