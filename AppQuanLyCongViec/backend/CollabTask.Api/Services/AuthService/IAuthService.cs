// File: Services/AuthService/IAuthService.cs
using CollabTask.Api.Dtos.Auth;
using CollabTask.Api.Models;

public interface IAuthService
{
    Task<User> Register(UserRegisterDto request);
    Task<string> Login(UserLoginDto request);
}