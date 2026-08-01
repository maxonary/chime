export interface ResearchResult {
  query: string;
  results: Citation[];
  timestamp: Date;
}

export interface Citation {
  title: string;
  url: string;
  snippet: string;
  source?: string;
}

const PERPLEXITY_API_KEY = process.env.PERPLEXITY_API_KEY;

export async function searchPerplexity(query: string): Promise<ResearchResult> {
  if (!PERPLEXITY_API_KEY) {
    console.warn("[research] PERPLEXITY_API_KEY not set, research disabled");
    return { query, results: [], timestamp: new Date() };
  }

  try {
    const response = await fetch("https://api.perplexity.ai/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${PERPLEXITY_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "sonar-pro",
        messages: [
          {
            role: "user",
            content: `Research this query and provide citations: ${query}`,
          },
        ],
        search_domain_filter: ["perplexity.com"],
        return_images: false,
        return_related_questions: false,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error("[research] Perplexity error:", error);
      return { query, results: [], timestamp: new Date() };
    }

    const data = (await response.json()) as {
      choices?: Array<{
        message?: { content?: string };
      }>;
      citations?: string[];
    };

    // Parse citations from Perplexity response
    const citations: Citation[] = [];
    if (data.citations) {
      data.citations.forEach((url, index) => {
        citations.push({
          title: `Source ${index + 1}`,
          url,
          snippet: "",
          source: "Perplexity",
        });
      });
    }

    return {
      query,
      results: citations,
      timestamp: new Date(),
    };
  } catch (error) {
    console.error("[research] Search failed:", error);
    return { query, results: [], timestamp: new Date() };
  }
}

export function formatCitationsForAgent(citations: Citation[]): string {
  if (!citations.length) return "";

  return (
    "\n\n[Research sources]\n" +
    citations
      .map((c) => `- ${c.title}: ${c.url}`)
      .join("\n")
  );
}
