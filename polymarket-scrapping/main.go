package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/joho/godotenv"
	supabase "github.com/supabase-community/supabase-go"
	"golang.org/x/sync/errgroup"
	"google.golang.org/genai"
)

type Event struct {
	ID          string `json:"id"`
	Description string `json:"description"`
}
type MarketJSON struct {
	ID            string  `json:"id"`
	Question      string  `json:"question"`
	Description   string  `json:"description"`
	Volume        string  `json:"volume"`
	Events        []Event `json:"events"`
	Outcomes      string  `json:"outcomes"`
	OutcomePrices string  `json:"outcomePrices"`
}

type Market struct {
	ID            string    `json:"id"`
	Question      string    `json:"question"`
	Description   string    `json:"description"`
	Volume        string    `json:"volume"`
	Events        []Event   `json:"events"`
	Outcomes      []string  `json:"outcomes"`
	OutcomePrices []float64 `json:"outcomePrices"`
	Image         string    `json:"image"`
}

type MarketInsert struct {
	MarketID    string  `json:"marketid"`
	Question    string  `json:"question"`
	Description string  `json:"description"`
	Volume      float64 `json:"volume"`
	YesPrice    float64 `json:"yes_price"`
	ImageURL    string  `json:"image_url"`
}

var baseImagePrompt string
var basePromptOnce sync.Once
var baseDescriptionSystemPrompt string
var supabaseClient *supabase.Client

const sampleImgPath = "sample_img.png"

var sampleImage []byte

func loadBaseImagePrompt() error {
	var err error
	basePromptOnce.Do(func() {
		data, readErr := os.ReadFile("/Users/benliu/dev/hackharvard/polymarket-scrapping/marketImagePrompt.txt")
		if readErr != nil {
			err = readErr
			return
		}
		baseImagePrompt = string(data)
		data, readErr = os.ReadFile("/Users/benliu/dev/hackharvard/polymarket-scrapping/marketDescriptionPrompt.txt")
		if readErr != nil {
			err = readErr
			return
		}
		baseDescriptionSystemPrompt = string(data)
	})
	f, err := os.Open(sampleImgPath)
	if err != nil {
		return err
	}
	defer f.Close()
	data, err := io.ReadAll(f)
	if err != nil {
		return err
	}
	sampleImage = data
	return err
}

// uploadImageToSupabase uploads bytes to Supabase Storage and returns a public URL.
// Requires env vars: SUPABASE_URL, SUPABASE_BUCKET, and either SUPABASE_SERVICE_ROLE_KEY or SUPABASE_API_KEY.
func uploadImageToSupabase(ctx context.Context, objectPath string, imageBytes []byte) (string, error) {
	baseURL := os.Getenv("SUPABASE_URL")
	bucket := os.Getenv("SUPABASE_BUCKET")
	if bucket == "" {
		bucket = "images"
	}
	key := os.Getenv("SUPABASE_SERVICE_ROLE_KEY")
	if key == "" {
		key = os.Getenv("SUPABASE_API_KEY")
	}
	if baseURL == "" || key == "" {
		return "", fmt.Errorf("missing SUPABASE_URL or API key for storage upload")
	}

	putURL := fmt.Sprintf("%s/storage/v1/object/%s/%s", baseURL, bucket, objectPath)
	req, err := http.NewRequestWithContext(ctx, http.MethodPut, putURL, bytes.NewReader(imageBytes))
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", "Bearer "+key)
	req.Header.Set("Content-Type", "image/png")
	req.Header.Set("x-upsert", "true")
	req.Header.Set("Cache-Control", "public, max-age=31536000, immutable")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("upload failed (%d): %s", resp.StatusCode, string(body))
	}

	publicURL := fmt.Sprintf("%s/storage/v1/object/public/%s/%s", baseURL, bucket, objectPath)
	return publicURL, nil
}

func parseJSONEncodedStringSlice(s string) ([]string, error) {
	var arr []string
	if err := json.Unmarshal([]byte(s), &arr); err != nil {
		return nil, err
	}
	return arr, nil
}

func parsePriceStringsToFloats(priceStrings []string) ([]float64, error) {
	prices := make([]float64, 0, len(priceStrings))
	for _, s := range priceStrings {
		f, err := strconv.ParseFloat(s, 64)
		if err != nil {
			return nil, err
		}
		prices = append(prices, f)
	}
	return prices, nil
}

/*	func questionExists(marketID string) (bool, error) {
	data, _, err := supabaseClient.From("questions").Select("marketid", "", false).Eq("marketid", marketID).Limit(1, "").Execute()
	if err != nil {
		return false, err
	}
	var rows []map[string]any
	if err := json.Unmarshal(data, &rows); err != nil {
		return false, err
	}
	return len(rows) > 0, nil
}*/

func getWorkerLimit() int {
	s := os.Getenv("MARKET_WORKERS")
	if s == "" {
		return 5
	}
	n, err := strconv.Atoi(s)
	if err != nil || n < 1 {
		return 5
	}
	return n
}

func getBatchSize() int {
	s := os.Getenv("INSERT_BATCH_SIZE")
	if s == "" {
		return 5
	}
	n, err := strconv.Atoi(s)
	if err != nil || n < 1 {
		return 5
	}
	return n
}

func buildMarketImagePrompt(template string, market Market) string {

	prompt := strings.ReplaceAll(template, "{{MARKET_QUESTION}}", market.Question)
	prompt = strings.ReplaceAll(prompt, "{{MARKET_DESCRIPTION}}", market.Description)
	return prompt
}

func generateMarketImage(client *genai.Client, market Market) (string, error) {

	prompt := buildMarketImagePrompt(baseImagePrompt, market)
	res, err := client.Models.GenerateContent(context.Background(), "gemini-2.5-flash-image", []*genai.Content{
		{
			Parts: []*genai.Part{
				{Text: prompt},
			},
			Role: "user",
		}, {
			Parts: []*genai.Part{
				genai.NewPartFromBytes(sampleImage, "image/png"),
			},
			Role: "user",
		},
	}, &genai.GenerateContentConfig{})
	if err != nil {
		return "", err
	}
	for _, c := range res.Candidates {
		if c.Content == nil {
			continue
		}
		for _, p := range c.Content.Parts {
			if p.InlineData != nil {
				b64 := base64.StdEncoding.EncodeToString(p.InlineData.Data)
				return b64, nil
			}
		}
	}
	return "", fmt.Errorf("no image returned")
}
func generateMarketDescription(client *genai.Client, market Market) (string, error) {

	systemPrompt := baseDescriptionSystemPrompt
	res, err := client.Models.GenerateContent(context.Background(), "gemini-2.5-flash-lite", []*genai.Content{
		{
			Parts: []*genai.Part{
				{Text: market.Description},
			},
			Role: "user",
		},
	}, &genai.GenerateContentConfig{SystemInstruction: &genai.Content{Parts: []*genai.Part{
		{Text: systemPrompt},
	}}})
	if err != nil {
		return "", err
	}
	return res.Text(), nil
}

func grabMarkets(client *genai.Client) ([]Market, error) {
	baseURL := "https://gamma-api.polymarket.com/markets"
	u, _ := url.Parse(baseURL)
	params := url.Values{}
	params.Add("closed", "false")
	params.Add("volume_num_min", "50000")
	params.Add("limit", "3000")
	u.RawQuery = params.Encode()
	req, _ := http.NewRequest("GET", u.String(), nil)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Println(err)
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Println(err)
	}
	var marketsJSON []MarketJSON
	err = json.Unmarshal(body, &marketsJSON)
	if err != nil {
		fmt.Println(err)
	}
	if len(marketsJSON) == 0 {
		fmt.Println("no markets returned")
		return nil, fmt.Errorf("no markets returned")
	}
	var markets []Market
	var mu sync.Mutex
	var eg errgroup.Group
	eg.SetLimit(getWorkerLimit())
	for _, mj := range marketsJSON {
		mj := mj
		eg.Go(func() error {
			// Skip if question already exists for this market ID
			if idNum, err := strconv.Atoi(mj.ID); err == nil && idNum <= 529310 {
				return nil
			}
			outcomes, err := parseJSONEncodedStringSlice(mj.Outcomes)
			if err != nil {
				fmt.Println(err)
				return nil
			}
			priceStrings, err := parseJSONEncodedStringSlice(mj.OutcomePrices)
			if err != nil {
				fmt.Println(err)
				return nil
			}
			prices, err := parsePriceStringsToFloats(priceStrings)
			if err != nil {
				fmt.Println(err)
				return nil
			}
			market := Market{
				ID:            mj.ID,
				Question:      mj.Question,
				Description:   mj.Description,
				Volume:        mj.Volume,
				Events:        mj.Events,
				Outcomes:      outcomes,
				OutcomePrices: prices,
			}
			var (
				description string
				imageURL    string
			)
			var inner errgroup.Group
			inner.Go(func() error {
				d, err := generateMarketDescription(client, market)
				if err != nil {
					return fmt.Errorf("error generating market description: %w", err)
				}
				description = d
				return nil
			})
			inner.Go(func() error {
				i, err := generateMarketImage(client, market)
				if err != nil {
					return fmt.Errorf("error generating market image: %w", err)
				}
				// Best-effort upload to Supabase Storage; keep base64 for current app compatibility
				if imgBytes, decErr := base64.StdEncoding.DecodeString(i); decErr == nil {
					objectPath := fmt.Sprintf("%s.png", market.ID)
					if imageURL, err = uploadImageToSupabase(context.Background(), objectPath, imgBytes); err != nil {
						fmt.Println(err)
					}
				} else {
					fmt.Println(decErr)
				}
				return nil
			})
			if err := inner.Wait(); err != nil {
				fmt.Println(err)
				return nil
			}
			marketInsert := MarketInsert{
				MarketID:    market.ID,
				Question:    market.Question,
				Description: description,
				Volume:      func() float64 { v, _ := strconv.ParseFloat(market.Volume, 64); return v }(),
				YesPrice:    market.OutcomePrices[0],
				ImageURL:    imageURL,
			}
			if _, _, err := supabaseClient.From("questions").Insert(marketInsert, false, "", "", "").Execute(); err != nil {
				fmt.Println(err)
			}
			mu.Lock()
			markets = append(markets, market)
			mu.Unlock()
			return nil
		})
	}
	_ = eg.Wait()
	return markets, nil
}

func main() {
	_ = godotenv.Load()
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		fmt.Println("GEMINI_API_KEY not set. Create a .env with GEMINI_API_KEY or export it.")
		return
	}
	client, err := genai.NewClient(context.Background(), &genai.ClientConfig{
		APIKey:  apiKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		fmt.Println(err)
	}
	supabaseClient, err = supabase.NewClient(os.Getenv("SUPABASE_URL"), os.Getenv("SUPABASE_API_KEY"), &supabase.ClientOptions{})
	if err != nil {
		fmt.Println(err)
	}
	// load image gen prompt
	loadBaseImagePrompt()

	markets, err := grabMarkets(client)
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println(len(markets))

}
