import Link from "next/link";
import styles from "./page.module.css";

export default function Home() {
  const modules = [
    {
      title: "Encrypted Reputation Scores",
      description:
        "Aggregate proof-based credentials into private reputation vectors that dapps can query without exposing raw scores.",
      bullets: [
        "Ingest zk badge claims from Sismo, Gitcoin Passport, and custom attestations.",
        "Serve capability attestations that reveal only what a verifier needs to know.",
        "CoFHE-powered updates keep user weights encrypted end-to-end.",
      ],
    },
    {
      title: "Private Prediction Pools",
      description:
        "Run shielded markets where stakes, votes, and final tallies stay hidden until the community decides to reveal aggregates.",
      bullets: [
        "Accept shielded ZEC liquidity bridged through the Fhenix runtime.",
        "Encrypt outcomes and votes on the client; decrypt only final market aggregates.",
        "Support optional range reveals to communicate signal without leaking positions.",
      ],
    },
    {
      title: "Sybil-Resistant Identity",
      description:
        "Gate participation with verifiable humanity checks so each person controls a single encrypted voice in the commons.",
      bullets: [
        "Integrate BrightID, Gitcoin Passport, and ceremony-based attestations.",
        "Limit one encrypted stake or vote per verified participant.",
        "Composable identity adapters make it easy to plug new attestations in.",
      ],
    },
  ];

  const architecture = [
    {
      title: "Wallet & Client",
      details:
        "Users interact through a Next.js interface that prepares encrypted payloads with the Fhenix SDK and signs shielded transfers.",
    },
    {
      title: "CipherCommons Contracts",
      details:
        "Reputation, prediction, and identity engines execute on the Fhenix CoFHE network, keeping computations private by default.",
    },
    {
      title: "Off-chain Adapters",
      details:
        "Snapshot-style proposal bridges and oracle relays (Chainlink, UMA) mediate between real world outcomes and encrypted settlements.",
    },
  ];

  const roadmap = [
    {
      phase: "Hackathon Prototype",
      timeline: "Now",
      items: [
        "Encrypted YES/NO market with a 100-user cap.",
        "Reputation-gated participation using zk badges.",
        "Mock CoFHE hooks wired into permissioned execution.",
      ],
    },
    {
      phase: "Beta",
      timeline: "Q1 2026",
      items: [
        "Multi-outcome markets and encrypted LP shares.",
        "Bonding curves with privacy-preserving liquidity incentives.",
        "Integrations with DAO governance tools like Snapshot and Tally.",
      ],
    },
    {
      phase: "Launch",
      timeline: "Q2 2026",
      items: [
        "Production-grade mobile interface and SDK.",
        "Plugin architecture for third-party reputation sources.",
        "Advanced compliance and delegated permission controls.",
      ],
    },
  ];

  const stack = [
    "Fhenix CoFHE runtime",
    "Zcash shielded pools",
    "Sismo badges & Gitcoin Passport",
    "UMA and Chainlink oracles",
    "Next.js, wagmi, and Ethers",
  ];

  return (
    <div className={styles.page}>
      <header className={styles.hero}>
        <div className={styles.heroGlow} aria-hidden="true" />
        <div className={styles.heroContent}>
          <span className={styles.tag}>Zypherpunk – Zcash Privacy Hackathon</span>
          <h1>Coordinate in Full-Stack Privacy</h1>
          <p className={styles.subtitle}>
            CipherCommons blends encrypted reputation, shielded prediction markets, and
            sybil-resistant identity so communities can coordinate without leaking who
            they are or how much they stake.
          </p>
          <div className={styles.actions}>
            <Link href="#modules" className={styles.primaryAction}>
              Explore Modules
            </Link>
            <a
              className={styles.secondaryAction}
              href="https://book.getfoundry.sh/"
              target="_blank"
              rel="noreferrer"
            >
              View Build Notes
            </a>
          </div>
          <div className={styles.meta}>
            <span>Private Reputation & Prediction Playground</span>
            <span>Built with Fhenix CoFHE • Zcash • Sismo</span>
          </div>
        </div>
        <div className={styles.heroHighlights}>
          <div className={styles.highlightCard}>
            <span className={styles.highlightLabel}>Goal</span>
            <p>
              Showcase how fully homomorphic encryption unlocks playful, privacy-first
              social coordination primitives.
            </p>
          </div>
          <div className={styles.highlightCard}>
            <span className={styles.highlightLabel}>Stack</span>
            <ul>
              {stack.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
        </div>
      </header>

      <main className={styles.main}>
        <section id="modules" className={styles.section}>
          <div className={styles.sectionHeader}>
            <span className={styles.sectionTag}>Modules</span>
            <h2>Assemble Privacy-Native Building Blocks</h2>
            <p>
              Mix and match encrypted reputation, prediction, and identity systems to
              create playful-yet-compliant coordination spaces.
            </p>
          </div>
          <div className={styles.grid}>
            {modules.map((module) => (
              <article key={module.title} className={styles.card}>
                <h3>{module.title}</h3>
                <p>{module.description}</p>
                <ul>
                  {module.bullets.map((bullet) => (
                    <li key={bullet}>{bullet}</li>
                  ))}
                </ul>
              </article>
            ))}
          </div>
        </section>

        <section id="architecture" className={styles.section}>
          <div className={styles.sectionHeader}>
            <span className={styles.sectionTag}>Architecture</span>
            <h2>How CipherCommons Fits Together</h2>
            <p>
              A layered stack keeps sensitive reputation data encrypted from wallet to
              outcome settlement, while still integrating with familiar DAO tooling.
            </p>
          </div>
          <div className={styles.architectureGrid}>
            {architecture.map((item) => (
              <article key={item.title} className={styles.architectureCard}>
                <h3>{item.title}</h3>
                <p>{item.details}</p>
              </article>
            ))}
          </div>
        </section>

        <section id="roadmap" className={styles.section}>
          <div className={styles.sectionHeader}>
            <span className={styles.sectionTag}>Roadmap</span>
            <h2>Path to Production</h2>
            <p>
              From hackathon experiments to a production-grade coordination commons with
              extensible plugin support.
            </p>
          </div>
          <div className={styles.roadmap}>
            {roadmap.map((milestone) => (
              <article key={milestone.phase} className={styles.roadmapCard}>
                <div className={styles.roadmapHeading}>
                  <span className={styles.roadmapPhase}>{milestone.phase}</span>
                  <span className={styles.roadmapTimeline}>{milestone.timeline}</span>
                </div>
                <ul>
                  {milestone.items.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </article>
            ))}
          </div>
        </section>

        <section id="call-to-action" className={styles.section}>
          <div className={styles.sectionHeader}>
            <h2>Ready to Prototype?</h2>
            <p>
              Spin up encrypted markets, reputation attestations, and identity gates with
              the provided Foundry contracts and mock CoFHE testing harness.
            </p>
          </div>
          <div className={styles.footerActions}>
            <Link href="#modules" className={styles.primaryAction}>
              Review Core Modules
            </Link>
            <Link href="#roadmap" className={styles.secondaryAction}>
              See Delivery Roadmap
            </Link>
          </div>
        </section>
      </main>
    </div>
  );
}
