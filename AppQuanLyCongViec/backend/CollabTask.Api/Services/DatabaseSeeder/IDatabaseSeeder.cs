namespace CollabTask.Api.Services.DatabaseSeeder
{
    public interface IDatabaseSeeder
    {
        Task SeedAsync();
        Task ClearDataAsync();
        Task SeedLargeTaskDataForAITestingAsync();
    }
}
