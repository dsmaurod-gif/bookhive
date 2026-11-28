data "aws_cloudfront_cache_policy" "optimizada" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "sin_cache" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "todo_menos_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_origin_access_control" "app" {
  name                              = "${local.prefijo}-oac-app"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "borde" {
  # checkov:skip=CKV_AWS_86:Sin registro de acceso en el PMV para evitar costo de almacenamiento
  # checkov:skip=CKV_AWS_310:Sin segundo origen de conmutacion; una sola region en el PMV
  # checkov:skip=CKV2_AWS_32:La politica de cabeceras de seguridad se agrega en la evolucion
  # checkov:skip=CKV_AWS_174:Sin dominio propio se usa el certificado por defecto de CloudFront (TLS minimo 1.0); limitacion declarada
  # checkov:skip=CKV2_AWS_42:Sin dominio propio no hay certificado ACM personalizado; se usa el certificado por defecto de CloudFront
  # checkov:skip=CKV_AWS_374:BookHive atiende a migrantes en muchos paises y husos horarios; restringir por pais contradice el objetivo del producto
  enabled             = true
  default_root_object = "index.html"
  web_acl_id          = aws_wafv2_web_acl.borde.arn
  price_class         = "PriceClass_100"

  origin {
    origin_id                = "app-s3"
    domain_name              = "${var.bucket_app}.s3.${var.region}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.app.id
  }

  origin {
    origin_id   = "api-gateway"
    domain_name = split("/", replace(var.api_url, "https://", ""))[0]
    origin_path = "/${element(split("/", replace(var.api_url, "https://", "")), 1)}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    origin_id   = "alb-sync"
    domain_name = var.alb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "app-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimizada.id
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern             = "/api/*"
    target_origin_id         = "api-gateway"
    viewer_protocol_policy   = "https-only"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.sin_cache.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.todo_menos_host.id
  }

  ordered_cache_behavior {
    path_pattern             = "/ws*"
    target_origin_id         = "alb-sync"
    viewer_protocol_policy   = "https-only"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.sin_cache.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.todo_menos_host.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "app" {
  bucket = var.bucket_app

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "LecturaSoloCloudFront"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${var.bucket_app}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.borde.arn
          }
        }
      }
    ]
  })
}