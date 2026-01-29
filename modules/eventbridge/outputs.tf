output "event_rule_arn" {
  value = aws_cloudwatch_event_rule.mediaconvert_job_state.arn
}
