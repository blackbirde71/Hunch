package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"

	supabase "github.com/supabase-community/supabase-go"
	"google.golang.org/genai"
)

func findVideos(supabaseClient *supabase.Client) error {
	data, _, err := supabaseClient.From("questions").Select("*", "", false).Is("video_url", "null").Execute()
	if err != nil {
		return err
	}
	var rows []map[string]any
	if err := json.Unmarshal(data, &rows); err != nil {
		return err
	}
	for _, row := range rows {
		question := row["question"].(string)
		queries := determineSemanticSearch(question)
		if len(queries) == 0 {
			continue
		}
		for _, query := range queries {
			videoURL := getVideoFromTwitter(query)
			fmt.Println(videoURL)
			if videoURL != "" {
				_, _, err := supabaseClient.From("questions").Update(map[string]any{
					"video_url": videoURL,
				}, "", "").Eq("question", row["question"].(string)).Execute()
				if err != nil {
					return err
				}
				break
			}
		}
	}
	return nil
}
func determineSemanticSearch(question string) []string {
	client, err := genai.NewClient(context.Background(), &genai.ClientConfig{
		APIKey:  os.Getenv("GEMINI_API_KEY"),
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		fmt.Println(err)
		return []string{}
	}
	res, err := client.Models.GenerateContent(context.Background(), "gemini-2.5-flash-lite", []*genai.Content{
		{
			Parts: []*genai.Part{
				{Text: question},
			},
			Role: "user",
		},
	}, &genai.GenerateContentConfig{SystemInstruction: &genai.Content{Parts: []*genai.Part{
		{Text: "Based on a given prediction market question, determine relevant twitter advanced searches to perform to get relevant news on the market. Example Question: How many gold cards will trump sell this year? Example Answer: [\"trump gold card\", \"gold cards\", \"trump card\"]. Strongly prefer shorter, minimal queries. Do not include words like update, latest news, status, end date, etc. Return the TOP FOUR queries. The last two queries should be broader and less specific. Return your answer as a JSON array of strings. Question: When will the Government shutdown end?"},
	}}})
	if err != nil {
		fmt.Println(err)
		return []string{}
	}
	var queries []string
	text := strings.TrimSpace(res.Text())
	// Strip code fences if present
	if strings.HasPrefix(text, "```") {
		text = strings.TrimPrefix(text, "```")
		text = strings.TrimPrefix(text, "json")
		text = strings.TrimSpace(text)
		if idx := strings.LastIndex(text, "```"); idx != -1 {
			text = text[:idx]
		}
		text = strings.TrimSpace(text)
	}
	// First try to unmarshal directly into []string
	if err := json.Unmarshal([]byte(text), &queries); err == nil {
		return queries
	}
	// If it's a JSON string that contains the array, unmarshal to string first
	var inner string
	if err := json.Unmarshal([]byte(text), &inner); err == nil {
		text = inner
	}
	// Extract bracketed array content if surrounding text exists
	if i := strings.Index(text, "["); i != -1 {
		if j := strings.LastIndex(text, "]"); j != -1 && j > i {
			text = text[i : j+1]
		}
	}
	text = strings.Trim(text, "` \n\t")
	if err := json.Unmarshal([]byte(text), &queries); err == nil {
		return queries
	}
	fmt.Println("Failed to parse response as JSON array")
	return []string{}
}

type TwitterResponse struct {
	Tweets []Tweet `json:"tweets"`
}
type Tweet struct {
	ID               string            `json:"id"`
	ExtendedEntities *ExtendedEntities `json:"extendedEntities"`
}

type ExtendedEntities struct {
	Media []Media `json:"media"`
}

type Media struct {
	Type      string     `json:"type"`
	VideoInfo *VideoInfo `json:"video_info"`
}

type VideoInfo struct {
	Variants []Variant `json:"variants"`
}

type Variant struct {
	Bitrate     *int   `json:"bitrate,omitempty"`
	ContentType string `json:"content_type"`
	URL         string `json:"url"`
}

func getVideoFromTwitter(searchQuery string) string {
	u, err := url.Parse("https://api.twitterapi.io/twitter/tweet/advanced_search")
	if err != nil {
		fmt.Println(err)
		return ""
	}
	params := u.Query()
	params.Set("query", searchQuery)
	params.Set("queryType", "Top")
	u.RawQuery = params.Encode()

	req, err := http.NewRequest(http.MethodGet, u.String(), nil)
	if err != nil {
		fmt.Println(err)
		return ""
	}
	apiKey := os.Getenv("TWITTER_API_KEY")
	if apiKey == "" {
		fmt.Println("missing TWITTER_API_KEY")
		return ""
	}
	req.Header.Set("X-API-Key", apiKey)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println(err)
		return ""
	}
	defer res.Body.Close()

	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println(err)
		return ""
	}
	// Try wrapper shape { tweets: [...] }
	var tr TwitterResponse
	if err := json.Unmarshal(body, &tr); err == nil && len(tr.Tweets) > 0 {
		for _, t := range tr.Tweets {
			if url := bestVideoFromTweet(t); url != "" {
				return url
			}
		}
	}
	// Try single tweet object
	var single Tweet
	if err := json.Unmarshal(body, &single); err == nil {
		if url := bestVideoFromTweet(single); url != "" {
			return url
		}
	}
	// Try array of tweets
	var arr []Tweet
	if err := json.Unmarshal(body, &arr); err == nil {
		for _, t := range arr {
			if url := bestVideoFromTweet(t); url != "" {
				return url
			}
		}
	}
	return ""
}

func bestVideoFromTweet(t Tweet) string {
	if t.ExtendedEntities == nil {
		return ""
	}
	// Prefer the first MP4 variant
	for _, m := range t.ExtendedEntities.Media {
		if m.VideoInfo == nil {
			continue
		}
		for _, v := range m.VideoInfo.Variants {
			if v.URL != "" && v.ContentType == "video/mp4" {
				return v.URL
			}
		}
	}
	// Fallback: first available variant URL of any type
	for _, m := range t.ExtendedEntities.Media {
		if m.VideoInfo == nil {
			continue
		}
		for _, v := range m.VideoInfo.Variants {
			if v.URL != "" {
				return v.URL
			}
		}
	}
	return ""
}
