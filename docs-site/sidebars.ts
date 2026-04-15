import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'overview',
    'getting-started',
    {
      type: 'category',
      label: 'Scenarios',
      items: [
        {
          type: 'category',
          label: 'Webstore: Container Apps',
          items: [
            'scenarios/webstore-container-apps/architecture',
            'scenarios/webstore-container-apps/demo-script',
            'scenarios/webstore-container-apps/prompts',
          ],
        },
        {
          type: 'category',
          label: 'AKS: Blue/Green Deployment',
          items: [
            'scenarios/aks-blue-green/architecture',
            'scenarios/aks-blue-green/demo-script',
            'scenarios/aks-blue-green/prompts',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'SRE Agent Concepts',
      items: ['concepts/incident-response', 'concepts/run-modes', 'concepts/connectors'],
    },
    'reference',
  ],
};

export default sidebars;
