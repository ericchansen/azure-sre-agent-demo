import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

function HeroSection() {
  return (
    <header className="hero-azure">
      <div className="container">
        <Heading as="h1">Azure SRE Agent Demo</Heading>
        <p>
          Watch an AI agent detect a live application failure, investigate the root cause
          across logs, metrics, and source code, and remediate it — all without human intervention.
        </p>
        <div className="hero-buttons">
          <Link className="button button--primary button--lg" to="/docs/demo-script">
            🎤 Demo Script
          </Link>
          <Link className="button button--outline button--lg" to="/docs/overview">
            📖 Read the Docs
          </Link>
          <Link
            className="button button--outline button--lg"
            href="https://sre.azure.com/docs/"
          >
            ↗ Azure SRE Agent Docs
          </Link>
        </div>
      </div>
    </header>
  );
}

const features = [
  {
    icon: '🔍',
    title: 'Autonomous Investigation',
    description:
      'The SRE Agent correlates Application Insights telemetry, Azure Monitor metrics, and deployment history to pinpoint root cause — in seconds, not hours.',
    link: 'https://sre.azure.com/docs/capabilities/root-cause-analysis',
  },
  {
    icon: '🧠',
    title: 'Code-Aware Reasoning',
    description:
      'Connected to your GitHub repo, the agent traces failures back to the exact source code path using Deep Context — not just "something is 503-ing."',
    link: 'https://sre.azure.com/docs/concepts/workspace-tools',
  },
  {
    icon: '⚡',
    title: 'Review or Autonomous Mode',
    description:
      'Start in Review mode (propose & approve). Graduate to Autonomous for trusted patterns. You control the blast radius.',
    link: 'https://sre.azure.com/docs/concepts/run-modes',
  },
  {
    icon: '🧩',
    title: 'Extensible via Connectors',
    description:
      'Built-in: Azure Monitor, App Insights, Log Analytics. Plus Teams, Outlook, PagerDuty, ServiceNow, Kusto, and any API via MCP.',
    link: 'https://sre.azure.com/docs/concepts/connectors',
  },
  {
    icon: '🗂️',
    title: 'Memory That Compounds',
    description:
      'Every investigation teaches the agent. It remembers root causes, resolution steps, and team patterns — institutional knowledge that never walks out the door.',
    link: 'https://sre.azure.com/docs/concepts/memory',
  },
  {
    icon: '🔁',
    title: 'Fully Repeatable Demo',
    description:
      'One-click GitHub Actions workflows break and restore checkout on demand. Run the demo as many times as you need — same story every time.',
    link: '/docs/overview#demo-workflows',
  },
];

function FeaturesSection() {
  return (
    <section className="features-section">
      <div className="container">
        <div className="text--center margin-bottom--xl">
          <Heading as="h2">Why Azure SRE Agent?</Heading>
          <p style={{fontSize: '1.1rem', maxWidth: 600, margin: '0 auto'}}>
            It doesn't just alert you. It investigates, reasons, and acts.
          </p>
        </div>
        <div className="row">
          {features.map((f, i) => (
            <div className="col col--4 margin-bottom--lg" key={i}>
              <div className="feature-card">
                <div className="feature-icon">{f.icon}</div>
                <Heading as="h3">{f.title}</Heading>
                <p>{f.description}</p>
                <Link href={f.link} style={{fontWeight: 600}}>
                  Learn more →
                </Link>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function DemoFlowSection() {
  const steps = [
    {title: 'Healthy Baseline', desc: 'The webstore is running. Customers browse, add to cart, check out. Telemetry flows to Application Insights.'},
    {title: 'Break Checkout', desc: 'One-click workflow sets DEMO_BROKEN_CHECKOUT=true. The checkout API returns 503 while the rest of the site stays up.'},
    {title: 'Agent Detects', desc: 'Azure SRE Agent sees the spike in 503 errors. It queries App Insights, examines traces, and correlates with recent changes.'},
    {title: 'Agent Investigates', desc: 'The agent traces the failure to the DEMO_BROKEN_CHECKOUT flag in the source code. It forms a hypothesis and validates it with evidence.'},
    {title: 'Agent Remediates', desc: 'In Review mode: proposes resetting the env var. In Autonomous mode: executes the fix immediately.'},
    {title: 'Recovery', desc: 'Checkout returns to 201. App Insights confirms the fix. The agent saves the investigation to memory for next time.'},
  ];

  return (
    <section className="demo-flow">
      <div className="container">
        <div className="text--center margin-bottom--xl">
          <Heading as="h2">The Demo Flow</Heading>
          <p style={{fontSize: '1.1rem', maxWidth: 600, margin: '0 auto'}}>
            Six steps from healthy to broken to automatically recovered.
          </p>
        </div>
        <div style={{maxWidth: 700, margin: '0 auto'}}>
          {steps.map((s, i) => (
            <div className="flow-step" key={i}>
              <div className="flow-step-number">{i + 1}</div>
              <div className="flow-step-content">
                <Heading as="h3">{s.title}</Heading>
                <p>{s.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function CtaSection() {
  return (
    <section className="cta-section">
      <div className="container">
        <Heading as="h2">Ready to run the demo?</Heading>
        <p>Follow the demo script for a step-by-step walkthrough with speaker notes.</p>
        <div className="hero-buttons">
          <Link className="button button--primary button--lg" to="/docs/demo-script">
            🎤 Open Demo Script
          </Link>
          <Link
            className="button button--outline button--lg"
            href="https://sre.azure.com/docs/get-started/create-and-setup"
          >
            🚀 Create Your Own Agent
          </Link>
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  return (
    <Layout
      title="AI-Powered Incident Response Demo"
      description="End-to-end demo of Azure SRE Agent detecting and remediating a live application failure."
    >
      <HeroSection />
      <FeaturesSection />
      <DemoFlowSection />
      <CtaSection />
    </Layout>
  );
}
