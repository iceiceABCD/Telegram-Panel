using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using TelegramPanel.Core.Models;

namespace TelegramPanel.Web.ExternalApi;

/// <summary>
/// 验证码分享公开 API 控制器
/// 无需认证，允许客户查看验证码和2FA信息
/// </summary>
[ApiController]
[Route("api/public/verification")]
public class VerificationShareController : ControllerBase
{
    private readonly ILogger<VerificationShareController> _logger;
    // 注入您的服务接口
    // private readonly IVerificationShareService _verificationShareService;

    public VerificationShareController(ILogger<VerificationShareController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// 获取分享配置信息及验证码列表
    /// GET: /api/public/verification/share/{shareId}
    /// </summary>
    [HttpGet("share/{shareId}")]
    [ProducesResponseType(typeof(VerificationShareResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetShareConfig(string shareId)
    {
        try
        {
            _logger.LogInformation($"Fetching verification share config: {shareId}");
            
            // TODO: 实现从数据库获取配置
            // var config = await _verificationShareService.GetConfigByShareIdAsync(shareId);
            
            var response = new VerificationShareResponse
            {
                Success = true,
                Message = "获取成功",
                Data = new ShareConfigDto
                {
                    ShareId = shareId,
                    Name = "示例分享",
                    Description = "这是一个示例验证码分享链接",
                    HtmlAnnouncement = "<p>欢迎查看验证码！</p>",
                    ContactInfo = new { Email = "support@example.com" },
                    VerificationCodes = new List<VerificationCodeDto>()
                }
            };

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error fetching verification share config: {shareId}");
            return NotFound(new { success = false, message = "分享链接不存在或已过期" });
        }
    }

    /// <summary>
    /// 获取分享配置下的所有验证码记录
    /// GET: /api/public/verification/share/{shareId}/codes
    /// </summary>
    [HttpGet("share/{shareId}/codes")]
    [ProducesResponseType(typeof(VerificationCodesResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVerificationCodes(string shareId)
    {
        try
        {
            _logger.LogInformation($"Fetching verification codes for share: {shareId}");
            
            // TODO: 实现从数据库获取验证码列表
            var response = new VerificationCodesResponse
            {
                Success = true,
                Message = "获取成功",
                Data = new List<VerificationCodeDto>()
            };

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error fetching verification codes: {shareId}");
            return NotFound(new { success = false, message = "获取验证码失败" });
        }
    }

    /// <summary>
    /// 标记验证码为已查看
    /// POST: /api/public/verification/codes/{codeId}/view
    /// </summary>
    [HttpPost("codes/{codeId}/view")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkCodeAsViewed(int codeId)
    {
        try
        {
            _logger.LogInformation($"Marking verification code as viewed: {codeId}");
            
            // TODO: 实现标记已查看逻辑
            return Ok(new { success = true, message = "已标记为已查看" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error marking code as viewed: {codeId}");
            return NotFound(new { success = false, message = "操作失败" });
        }
    }
}

/// <summary>
/// 响应 DTO
/// </summary>
public class VerificationShareResponse
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public ShareConfigDto? Data { get; set; }
}

public class ShareConfigDto
{
    public string ShareId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string HtmlAnnouncement { get; set; } = string.Empty;
    public object? ContactInfo { get; set; }
    public List<VerificationCodeDto> VerificationCodes { get; set; } = new();
}

public class VerificationCodeDto
{
    public int Id { get; set; }
    public string PhoneNumber { get; set; } = string.Empty;
    public string VerificationCode { get; set; } = string.Empty;
    public string CodeType { get; set; } = "SMS";
    public DateTime ExpiredAt { get; set; }
    public bool IsViewed { get; set; }
    public bool IsVerified { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class VerificationCodesResponse
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public List<VerificationCodeDto> Data { get; set; } = new();
}