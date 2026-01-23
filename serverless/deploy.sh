
#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-random-six}"
STAGE="${2:-dev}"
REGION="${3:-ap-southeast-1}"
FUNCTION="${4:-randomSix}"
STACK_NAME="${SERVICE}-${STAGE}"

echo "Service=$SERVICE Stage=$STAGE Region=$REGION Function=$FUNCTION"

# Đảm bảo serverless có sẵn (qua npx)
if ! npx serverless --version >/dev/null 2>&1; then
  echo "Installing npm deps..."
  npm i --no-audit --no-fund
fi

# Kiểm tra stack
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" >/dev/null 2>&1; then
  STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query "Stacks[0].StackStatus" --output text || echo "")
  if [ "$STATUS" = "UPDATE_ROLLBACK_FAILED" ]; then
    echo "Stack kẹt UPDATE_ROLLBACK_FAILED. Gỡ khoá..."
    aws cloudformation continue-update-rollback --stack-name "$STACK_NAME" --region "$REGION" || true
    sleep 10
  fi
  echo "==> Stack tồn tại. Chỉ deploy code function..."
  npx serverless deploy function -f "$FUNCTION" --stage "$STAGE" --region "$REGION"
else
  echo "==> Chưa có stack. Deploy full..."
  npx serverless deploy --stage "$STAGE" --region "$REGION"
fi

echo "Done."
