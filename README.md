# API Redirect Terraform Module

This was a fun module created to solve a repeated problem for me, cosmetic domains and cosmetic redirect with SSL integration. This module will create an API Gateway with Lambda Python housed in data.tf. Configure variable domain_name as the cosmetic domain, certificate_arn with cosmetic public domain SAN, and target_domain to the complex URL you wish to redirect cosmetically. Terraform will output the d-api redirect for CNAME or Alias redirect. 

Process can be tested using the disable_execute_api_endpoint = false and test the API endpoint output.

## Features

- **301 Permanent Redirects** - SEO-friendly permanent redirects.
- **Path Preservation** - Maintains original URL paths and query strings.
- **Custom Domain Support** - SSL certificate integration.
- **Serverless Architecture** - Lambda + API Gateway for scalability.
- **Comprehensive Logging** - CloudWatch integration for monitoring.

## 📋 Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- SSL certificate in AWS Certificate Manager (for custom domains)
- Domain name configured in Route 53 (optional, for custom domains)

## 🔧 Usage

### Basic Example

```hcl
module "api_redirect" {
  source = "./path/to/api-redirect"

  target_domain    = "new.example.com"
  stackname        = "my-redirect-service"
  domain_name      = "old.example.com"
  certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/abc123-def456"
}
```

### Advanced Example with Variables

```hcl
# variables.tf
variable "target_domain" {
  description = "Destination domain for redirects"
  type        = string
}

variable "source_domain" {
  description = "Source domain that will redirect"
  type        = string
}

# main.tf
module "api_redirect" {
  source = "./modules/api-redirect"

  target_domain   = var.target_domain
  stackname       = "production-redirect"
  domain_name     = var.source_domain
  certificate_arn = data.aws_acm_certificate.main.arn
  region          = "us-east-1"
}

# Get certificate from ACM
data "aws_acm_certificate" "main" {
  domain      = var.source_domain
  statuses    = ["ISSUED"]
  most_recent = true
}
```

## Input Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `target_domain` | Destination domain for 301 redirect (e.g., new.example.com) | `string` | - | ✅ Yes |
| `stackname` | Name for the redirect stack (used for resource naming) | `string` | `"demo-redirect-stack"` | ❌ No |
| `domain_name` | Custom domain name for the redirect service | `string` | `"www.example.com"` | ❌ No |
| `certificate_arn` | AWS Certificate Manager ARN for SSL certificate | `string` | - | ✅ Yes |
| `region` | AWS region to deploy resources | `string` | `"us-east-1"` | ❌ No |

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Custom Domain │───▶│  API Gateway     │───▶│   Lambda        │
│   (Route 53)    │    │  HTTP API        │    │   Function      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  CloudWatch      │    │   CloudWatch    │
                       │  Metrics         │    │   Logs          │
                       └──────────────────┘    └─────────────────┘
```

## 🔍 Testing

### Using Default API Gateway URL

After deployment, you can test using the default API Gateway URL:

```bash
# Get the invoke URL from Terraform output
terraform output api_gateway_invoke_url

# Test the redirect
curl -I "https://your-api-id.execute-api.us-east-1.amazonaws.com/test-path?param=value"
```

### Using Custom Domain

```bash
# Test with custom domain
curl -I "https://old.example.com/test-path?param=value"
```

Expected response:
```
HTTP/1.1 301 Moved Permanently
Location: https://new.example.com/test-path?param=value
```

## 📊 Monitoring & Logging

### CloudWatch Logs

The module creates two log groups:

1. **Lambda Logs**: `/aws/lambda/{stackname}`
   - Request/response logging
   - Error handling
   - Performance metrics

2. **API Gateway Metrics**: Available in CloudWatch
   - Request count
   - Latency
   - Error rates

### Sample Lambda Log Output

```json
{
  "level": "INFO",
  "message": "Received request: {\"rawPath\": \"/api/test\", \"rawQueryString\": \"param=value\"}",
  "timestamp": "2024-01-01T12:00:00Z"
}
{
  "level": "INFO", 
  "message": "Redirecting to: https://new.example.com/api/test?param=value",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. "Message Not Found" Error
- **Cause**: API Gateway endpoint disabled or Lambda integration issue
- **Solution**: Ensure `disable_execute_api_endpoint = false` in API Gateway

#### 2. SSL Certificate Errors
- **Cause**: Certificate not in the correct region or domain mismatch
- **Solution**: Verify certificate ARN and ensure it's in the same region as API Gateway

#### 3. Lambda Not Triggered
- **Cause**: IAM permissions or integration configuration
- **Solution**: Check Lambda execution role and API Gateway integration

### Debugging Steps

1. **Check Lambda Logs**:
   ```bash
   aws logs tail /aws/lambda/{stackname} --follow
   ```

2. **Verify API Gateway Integration**:
   ```bash
   aws apigatewayv2 get-integration --api-id {api-id} --integration-id {integration-id}
   ```

3. **Test Lambda Directly**:
   ```bash
   aws lambda invoke --function-name {function-name} --payload '{"rawPath": "/test", "rawQueryString": ""}' response.json
   ```

## 🔒 Security

- **TLS 1.2** enforced for all HTTPS connections
- **IAM Roles** with minimal required permissions
- **CloudWatch Logs** for audit trail
- **No sensitive data** stored in Lambda function

## 📈 Performance

- **1-second timeout** for Lambda function
- **Auto-scaling** based on demand
- **Regional API Gateway** for low latency
- **CloudFront ready** for global distribution

## 🗑️ Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: This will remove all created resources including Lambda function, API Gateway, and CloudWatch log groups.

## TO DO 
- Move from certificate string to certificate resource with dynamic resource creation.
- Create Route 53 records as part of stand-up.
- Private API and Lambda versus Public API and Lambda

## License

This module is provided as-is for educational and production use.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review CloudWatch logs for error details
3. Verify all prerequisites are met
4. Open an issue with detailed error information

---
### Contact - ryan@caledoniacloud.com
