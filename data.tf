data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

data "archive_file" "redirect_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"

  source {
    filename = "handler.py"
    content  = <<-PYTHON
      import re
      import json
      import logging

      # Configure logging
      logger = logging.getLogger()
      logger.setLevel(logging.INFO)

      # Domain injected at build time by Terraform
      _DEST = "${var.target_domain}"

      def main(event, context):
          # Log the incoming request
          logger.info(f"Received request: {json.dumps(event)}")
          
          try:
              # Extract the domain (strip http/https)
              dest_domain = re.sub(r'^https?://', '', _DEST)
              logger.info(f"Target domain: {dest_domain}")

              # Get request path and query string
              raw_path = event.get("rawPath", "/")
              qs       = event.get("rawQueryString", "")
              
              logger.info(f"Original path: {raw_path}")
              logger.info(f"Query string: {qs}")

              # Build the redirect URL
              new_url = f"https://{dest_domain}{raw_path}"
              if qs:
                  new_url += f"?{qs}"
              
              logger.info(f"Redirecting to: {new_url}")

              response = {
                  "statusCode": 301,
                  "headers": {
                      "Location": new_url,
                      "Cache-Control": "no-cache, no-store, must-revalidate",
                      "Pragma": "no-cache",
                      "Expires": "0"
                  }
              }
              
              logger.info(f"Returning response: {json.dumps(response)}")
              return response
              
          except Exception as e:
              logger.error(f"Error processing request: {str(e)}")
              return {
                  "statusCode": 500,
                  "headers": {
                      "Content-Type": "text/plain"
                  },
                  "body": "Internal Server Error"
              }
    PYTHON
  }
}
