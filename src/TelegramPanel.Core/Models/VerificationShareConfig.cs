namespace TelegramPanel.Core.Models;

/// <summary>
/// 验证码/2FA 分享配置模型
/// </summary>
public class VerificationShareConfig
{
    public int Id { get; set; }

    /// <summary>
    /// 分享链接标识符（唯一）
    /// </summary>
    public string ShareId { get; set; } = string.Empty;

    /// <summary>
    /// 分享名称
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// 分享描述
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// API 接码配置 URL
    /// </summary>
    public string SmsApiUrl { get; set; } = string.Empty;

    /// <summary>
    /// API 密钥
    /// </summary>
    public string SmsApiKey { get; set; } = string.Empty;

    /// <summary>
    /// HTML 公告内容
    /// </summary>
    public string HtmlAnnouncement { get; set; } = string.Empty;

    /// <summary>
    /// 联系方式（JSON 格式）
    /// </summary>
    public string ContactInfo { get; set; } = string.Empty;

    /// <summary>
    /// 是否启用
    /// </summary>
    public bool IsEnabled { get; set; } = true;

    /// <summary>
    /// 创建时间
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// 更新时间
    /// </summary>
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// 所有者账户 ID
    /// </summary>
    public string OwnerAccountId { get; set; } = string.Empty;
}

/// <summary>
/// 验证码记录模型
/// </summary>
public class VerificationRecord
{
    public int Id { get; set; }

    /// <summary>
    /// 所属分享配置
    /// </summary>
    public int ConfigId { get; set; }

    /// <summary>
    /// 电话号码
    /// </summary>
    public string PhoneNumber { get; set; } = string.Empty;

    /// <summary>
    /// 验证码
    /// </summary>
    public string VerificationCode { get; set; } = string.Empty;

    /// <summary>
    /// 验证码类型（SMS/2FA/Email 等）
    /// </summary>
    public string CodeType { get; set; } = "SMS";

    /// <summary>
    /// 验证码过期时间
    /// </summary>
    public DateTime ExpiredAt { get; set; }

    /// <summary>
    /// 是否已查看
    /// </summary>
    public bool IsViewed { get; set; } = false;

    /// <summary>
    /// 是否已验证
    /// </summary>
    public bool IsVerified { get; set; } = false;

    /// <summary>
    /// 创建时间
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// 关联的 Telegram 账户 ID
    /// </summary>
    public string TelegramAccountId { get; set; } = string.Empty;
}

/// <summary>
/// 联系信息模型
/// </summary>
public class ContactInfo
{
    public string? Email { get; set; }

    public string? Phone { get; set; }

    public string? Telegram { get; set; }

    public string? Wechat { get; set; }

    public string? QQ { get; set; }

    public string? Website { get; set; }

    public string? CustomField { get; set; }
}