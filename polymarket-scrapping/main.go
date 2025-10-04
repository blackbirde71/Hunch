package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"

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
}

const (
	geminiAPIKey = "AIzaSyB011HqN457B96XZMPMYKp23t9WwAHtDWw"
)

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

func grabMarkets(client *genai.Client) ([]Market, error) {
	baseURL := "https://gamma-api.polymarket.com/markets"
	u, _ := url.Parse(baseURL)
	params := url.Values{}
	params.Add("closed", "false")
	params.Add("volume_num_min", "30000")
	params.Add("limit", "200")
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
	for _, marketJSON := range marketsJSON {
		// Decode JSON-encoded strings into slices
		outcomes, err := parseJSONEncodedStringSlice(marketJSON.Outcomes)
		if err != nil {
			fmt.Println(err)
			return nil, fmt.Errorf("error parsing outcomes")
		}
		priceStrings, err := parseJSONEncodedStringSlice(marketJSON.OutcomePrices)
		if err != nil {
			fmt.Println(err)
			return nil, fmt.Errorf("error parsing outcome prices")
		}
		prices, err := parsePriceStringsToFloats(priceStrings)
		if err != nil {
			fmt.Println(err)
			return nil, fmt.Errorf("error parsing prices")
		}
		market := Market{
			ID:            marketJSON.ID,
			Question:      marketJSON.Question,
			Description:   marketJSON.Description,
			Volume:        marketJSON.Volume,
			Events:        marketJSON.Events,
			Outcomes:      outcomes,
			OutcomePrices: prices,
		}
		markets = append(markets, market)
	}
	return markets, nil
}

func main() {

	client, err := genai.NewClient(context.Background(), &genai.ClientConfig{
		APIKey:  geminiAPIKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		fmt.Println(err)
	}

	markets, err := grabMarkets(client)
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(len(markets))
}
