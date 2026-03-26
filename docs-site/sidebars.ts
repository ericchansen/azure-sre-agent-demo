import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'overview',
    'architecture',
    'getting-started',
    'demo-script',
    {
      type: 'category',
      label: 'SRE Agent Concepts',
      items: ['concepts/incident-response', 'concepts/run-modes', 'concepts/connectors'],
    },
    'reference',
  ],
};

export default sidebars;
