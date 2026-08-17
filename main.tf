provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://s3.localhost.localstack.cloud:4566"
  }
}

locals {
  frontend = [
    "nexus-cloud-frontend"
  ]
}

resource "aws_s3_bucket" "frontend_bucket" {
  count  = length(local.frontend)
  bucket = local.frontend[count.index]
}

resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  count  = length(local.frontend)
  bucket = aws_s3_bucket.frontend_bucket[count.index].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  count  = length(local.frontend)
  bucket = aws_s3_bucket.frontend_bucket[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket[count.index].arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.frontend_public_access
  ]
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  count  = length(local.frontend)
  bucket = aws_s3_bucket.frontend_bucket[count.index].id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "index_html" {
  count  = length(local.frontend)
  bucket = aws_s3_bucket.frontend_bucket[count.index].id
  key    = "index.html"

  source = "${path.module}/index.html"

  content_type = "text/html"
  etag         = filemd5("${path.module}/index.html")
}

resource "aws_s3_object" "style_css" {
  count  = length(local.frontend)
  bucket = aws_s3_bucket.frontend_bucket[count.index].id
  key    = "style.css"

  source = "${path.module}/style.css"

  content_type = "text/css"
  etag         = filemd5("${path.module}/style.css")
}

resource "aws_s3_object" "script_js" {
  count  = length(local.frontend)
  bucket = aws_s3_bucket.frontend_bucket[count.index].id
  key    = "script.js"

  source = "${path.module}/script.js"

  content_type = "application/javascript"
  etag         = filemd5("${path.module}/script.js")
}

output "frontend_url" {
  description = "URL do front-end Nexus Cloud hospedado no LocalStack"

  value = "https://${aws_s3_bucket.frontend_bucket[0].id}.s3-website.localhost.localstack.cloud:4566"
}