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

const BING_SEARCH_KEY = process.env.BING_SEARCH_KEY;

export async function searchBing(query: string): Promise<ResearchResult> {
  if (!BING_SEARCH_KEY) {
    console.warn("[research] BING_SEARCH_KEY not set, research disabled");
    return { query, results: [], timestamp: new Date() };
  }

  try {
    const url = new URL("https://api.bing.microsoft.com/v7.0/search");
    url.searchParams.append("q", query);
    url.searchParams.append("count", "5");
    url.searchParams.append("freshness", "Day");

    const response = await fetch(url.toString(), {
      method: "GET",
      headers: {
        "Ocp-Apim-Subscription-Key": BING_SEARCH_KEY,
      },
    });

    if (!response.ok) {
      const error = await response.text();
      console.error("[research] Bing error:", error);
      return { query, results: [], timestamp: new Date() };
    }

    const data = (await response.json()) as {
      webPages?: {
        value?: Array<{
          name: string;
          url: string;
          snippet: string;
        }>;
      };
    };

    const citations: Citation[] = [];
    if (data.webPages?.value) {
      data.webPages.value.forEach((result) => {
        citations.push({
          title: result.name,
          url: result.url,
          snippet: result.snippet,
          source: "Bing",
        });
      });
    }

    return {
      query,
      results: citations,
      timestamp: new Date(),
    };
  } catch (error) {
    console.error("[research] Bing search failed:", error);
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
