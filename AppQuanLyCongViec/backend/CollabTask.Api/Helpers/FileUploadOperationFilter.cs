using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace CollabTask.Api.Helpers
{
    public class FileUploadOperationFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            var fileParameters = context.ApiDescription.ParameterDescriptions
                .Where(p => p.ModelMetadata != null && p.ModelMetadata.ModelType == typeof(IFormFile))
                .ToList();

            if (!fileParameters.Any())
                return;

            // Clear existing parameters
            operation.Parameters.Clear();

            // Add taskId as path parameter
            var pathParams = context.ApiDescription.ParameterDescriptions
                .Where(p => p.Source.Id == "Path")
                .ToList();

            foreach (var param in pathParams)
            {
                operation.Parameters.Add(new OpenApiParameter
                {
                    Name = param.Name,
                    In = ParameterLocation.Path,
                    Required = true,
                    Schema = new OpenApiSchema { Type = "string", Format = "uuid" }
                });
            }

            // Set request body for file upload
            operation.RequestBody = new OpenApiRequestBody
            {
                Required = true,
                Content = new Dictionary<string, OpenApiMediaType>
                {
                    ["multipart/form-data"] = new OpenApiMediaType
                    {
                        Schema = new OpenApiSchema
                        {
                            Type = "object",
                            Properties = new Dictionary<string, OpenApiSchema>
                            {
                                ["file"] = new OpenApiSchema
                                {
                                    Type = "string",
                                    Format = "binary",
                                    Description = "File to upload (max 10MB)"
                                }
                            },
                            Required = new HashSet<string> { "file" }
                        }
                    }
                }
            };
        }
    }
}
