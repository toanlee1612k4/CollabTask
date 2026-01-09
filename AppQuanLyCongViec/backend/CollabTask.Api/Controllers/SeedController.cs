using CollabTask.Api.Services.DatabaseSeeder;
using Microsoft.AspNetCore.Mvc;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SeedController : ControllerBase
    {
        private readonly IDatabaseSeeder _seeder;

        public SeedController(IDatabaseSeeder seeder)
        {
            _seeder = seeder;
        }

        /// <summary>
        /// Seed database with sample data
        /// </summary>
        [HttpPost("seed")]
        public async Task<IActionResult> SeedDatabase()
        {
            try
            {
                await _seeder.SeedAsync();
                return Ok(new { message = "Database seeded successfully! Check console for details." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Seeding failed: {ex.Message}", detail = ex.ToString() });
            }
        }

        /// <summary>
        /// Clear all data from database
        /// </summary>
        [HttpPost("clear")]
        public async Task<IActionResult> ClearDatabase()
        {
            try
            {
                await _seeder.ClearDataAsync();
                return Ok(new { message = "Database cleared successfully!" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Clearing failed: {ex.Message}" });
            }
        }

        /// <summary>
        /// Clear and reseed database in one call
        /// </summary>
        [HttpPost("reseed")]
        public async Task<IActionResult> ReseedDatabase()
        {
            try
            {
                await _seeder.ClearDataAsync();
                await _seeder.SeedAsync();
                return Ok(new { message = "Database reseeded successfully! Check console for details." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Reseeding failed: {ex.Message}", detail = ex.ToString() });
            }
        }

        /// <summary>
        /// Seed 1000 tasks per user for AI testing
        /// </summary>
        [HttpPost("seed-ai-test-data")]
        public async Task<IActionResult> SeedAITestData()
        {
            try
            {
                await _seeder.SeedLargeTaskDataForAITestingAsync();
                return Ok(new { message = "AI test data seeded successfully! 1000 tasks per user created. Check console for details." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Seeding AI test data failed: {ex.Message}", detail = ex.ToString() });
            }
        }

        /// <summary>
        /// Clear and reseed with 1000 tasks per user for AI testing
        /// </summary>
        [HttpPost("reseed-ai-test")]
        public async Task<IActionResult> ReseedAITestData()
        {
            try
            {
                await _seeder.ClearDataAsync();
                await _seeder.SeedLargeTaskDataForAITestingAsync();
                return Ok(new { 
                    message = "Database reseeded with AI test data! 6000 tasks created (1000/user).",
                    endpoints = new {
                        test_bob = "GET /api/productivity/tasks/suggested - Login as bob@example.com (overdue priority)",
                        test_charlie = "GET /api/productivity/tasks/suggested - Login as charlie@example.com (short tasks first)",
                        test_diana = "GET /api/productivity/tasks/suggested - Login as diana@example.com (high priority first)"
                    }
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Reseeding AI test data failed: {ex.Message}", detail = ex.ToString() });
            }
        }
    }
}
