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
    //baseURL = "http://localhost:5030";
    //app.Logger.LogInformation("Init: base URL set: " + baseURL);
}

//--test POST
var testTweet = new Tweet("A123", "EN-US", new TwitterUser("paulyuk99", "picture", "Paul Y."), "This is great!", "This is great!");
//test post Dapr
app.Logger.LogInformation("--Simulating /tweets service invoked via Dapr...");
var daprClient = new Dapr.Client.DaprClientBuilder().Build();
var sTweet = await daprClient.InvokeMethodAsync<Tweet, AnalyzedTweet>("processor", "score", testTweet); //optionally use Dapr SDK for Service Invoke
app.Logger.LogInformation("--done test.");

//test post httpClient
app.Logger.LogInformation("--Simulating /tweets service invoked via HTTP...");
var hClient = HttpClientFactory.Create();

hClient.DefaultRequestHeaders.Add("dapr-app-id", "processor"); //only code needed for Dapr service discovery - add a header to enable HTTP Proxy
var res = await hClient.PostAsJsonAsync<Tweet>(baseURL + "/score", testTweet);
AnalyzedTweet aTweet = await res.Content.ReadFromJsonAsync<AnalyzedTweet>();
app.Logger.LogInformation("--done test.");
//--done test

app.MapPost("/tweets", async (Tweet t, Dapr.Client.DaprClient daprClient, IHttpClientFactory httpClientFactory) =>
 {

     app.Logger.LogInformation("/tweets service invoked...");
     var httpClient = httpClientFactory.CreateClient();
     httpClient.DefaultRequestHeaders.Add("dapr-app-id", "processor"); //only code needed for Dapr service discovery - add a header to enable HTTP Proxy
     var response = await httpClient.PostAsJsonAsync<Tweet>(baseURL + "/score", t);
     AnalyzedTweet scoredTweet = await response.Content.ReadFromJsonAsync<AnalyzedTweet>();
     //var scoredTweet = await daprClient.InvokeMethodAsync<Tweet, AnalyzedTweet>("processor", "score", t); //optionally use Dapr SDK for Service Invoke

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
                    string Text);

public record AnalyzedTweet(Tweet Tweet,
                            float score);