data "aws_acm_certificate" "cert" {
  domain      = "www.wbsecurecloud.dev"
  statuses    = ["ISSUED"]
  most_recent = true
}


resource "aws_kms_key" "main-kms-key" {
    description = "KMS key for services used"
    deletion_window_in_days = 7
}

resource "aws_wafv2_web_acl_association" "wordpres-waf-association" {
     resource_arn = aws_lb.load-balancer-us-east-1.arn
     web_acl_arn = aws_wafv2_web_acl.wordpress-waf.arn
}
# attaches the the WAF web ACL to the ALB
resource "aws_wafv2_web_acl" "wordpress-waf" {
   name = "wordpress-waf"
   scope = "REGIONAL" 
# defines the acl as a regional service as the ALB spans across all the AZs within the region
   default_action {
     allow {}
   }
   # for any action that doesnt match the block criteria (ON ALLOW BECAUSE ITS A PUBLIC WEBSITE)
   visibility_config {
     cloudwatch_metrics_enabled = true
     # sends WAF allowed + denied traffic counts to cloudwatch metrics for data
     metric_name = "wordpress-waf-metrics"
     sampled_requests_enabled = true
     # stores waf individual allowed + denied traffic for inspection
   }
   rule {
     name = "general_rate_limit_rule"
     priority = 3
     action {
       block {}
     }
     statement {
       rate_based_statement {
         limit = 2000
         # 2000 request limit for general requests outside the login page
         aggregate_key_type = "IP"
         # uses the IP address as the key type
       }
     }
     visibility_config {
       cloudwatch_metrics_enabled = true 
       metric_name = "general_rate_limit_rule"
       sampled_requests_enabled = true
     }
   }
   rule {
      name = "login_rate_limit_rule"
      priority = 2
      # sets the general priority level of the rule
      action {
        block {}
      }
      # if rule is bypassed in this case the rate limit rule is broken, it will block the traffic
      statement {
        rate_based_statement {
          limit = 20
          # need multiple limits (e.g. login page, requests) to block multiple login attemps and DDoS attacks
          aggregate_key_type = "IP"
          # tracks based off user IP addresss
          scope_down_statement {
            # scope down to create a more specific rate limit
            byte_match_statement {
            field_to_match {
                uri_path {}
              }
              # provides the path to the wordpress application
            search_string = "/wp-login.php"
            # login page for the wordpress application, searches for this page to connect to the rate limit configuration
            positional_constraint = "EXACTLY"
            # makes sure it hits the login page exactly, didnt choose "STARTS_WITH" because I wanted it to hit the login page exactly as shown in the search_string
            text_transformation {
              priority = 1
              type = "URL_DECODE"
             }
             text_transformation {
               priority = 2
               type = "LOWERCASE"
             }
             # higher security against case tricks and encoding that may bypass rate limit measures
            }
            # "byte_match_statement" used to isolate the rate limit to just the login page, configured to be a max of 20 attempts
        }
      }
      
   }
   visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name = "login_rate_limit_rule"
        sampled_requests_enabled = true
      }
    }
    rule {
      name = "AWSManagedRulesCommonRuleSet"
      priority = 1
      override_action {
        none{}
      }
      statement {
        managed_rule_group_statement {
          name = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true 
        metric_name = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled = true
      }
    }
    # utilizes AWS common rulesets for basic firewall measures against attacks like SQL injections XSS, etc.
  }
# creates rate limit rule

