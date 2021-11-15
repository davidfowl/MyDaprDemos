using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers().AddDapr();
builder.Services.AddHttpClient();

// Configure and enable middlewares
var app = builder.Build();

var baseURL = (Environment.GetEnvironmentVariable("BASE_URL") ?? "http://localhost") + ":" + (Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3500"); //reconfigure cpde to make requests to Dapr sidecar
app.Logger.LogInformation("Init: base URL set: " + baseURL);

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.MapPost("/tweets", async (Tweet t, IHttpClientFactory httpClientFactory, Dapr.Client.DaprClient daprClient) =>
 {
     app.Logger.LogInformation("/tweets service invoked, invoking processor service for score...");
     var httpClient = httpClientFactory.CreateClient();
     httpClient.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
     httpClient.DefaultRequestHeaders.Add("dapr-app-id", "processor"); //only new code needed for Dapr service discovery - add a header to enable HTTP Proxy

     var tweetJson = JsonSerializer.Serialize<Tweet>(t);
     var content = new StringContent(tweetJson, Encoding.UTF8, "application/json");

     app.Logger.LogInformation("Posting to: " + baseURL + "/score ; with: " + tweetJson);
     var response = await httpClient.PostAsync(baseURL + "/score", content);
     var responseBody = await response.Content.ReadAsStringAsync();

     AnalyzedTweet scoredTweet = JsonSerializer.Deserialize<AnalyzedTweet>(responseBody);
     app.Logger.LogInformation("Scored tweet: " + scoredTweet.ToString());

     //Alternately, replace above with Dapr SDK for Invoke
     //scoredTweet = await daprClient.InvokeMethodAsync<Tweet, AnalyzedTweet>("processor", "score", t); //optionally use Dapr SDK for Service Invoke

     app.Logger.LogInformation("/tweet scored, saving to state store");
     await daprClient.SaveStateAsync<AnalyzedTweet>("statestore", t.Id, scoredTweet);

     app.Logger.LogInformation("/tweet saved, publishing to pubsub");
     await daprClient.PublishEventAsync<AnalyzedTweet>("pubsub", "scored", scoredTweet);
     app.Logger.LogInformation("/tweet processed");
 });

await app.RunAsync();

app.Run();

public record TwitterUser([property: JsonPropertyName("screen_name")] string ScreenName, 
                          [property: JsonPropertyName("profile_image_url_https")] string Picture, 
                          string Name);

public record Tweet([property: JsonPropertyName("id_str")] string Id, 
                    [property: JsonPropertyName("lang")] string Language,
                    [property: JsonPropertyName("user")] TwitterUser Author,
                    [property: JsonPropertyName("full_text")] string FullText,
                    [property: JsonPropertyName("text")] string Text);

public record AnalyzedTweet([property: JsonPropertyName("tweet")] Tweet Tweet,
                            float score);