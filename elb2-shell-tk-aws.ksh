aws --profile a1  --region us-east-1  elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-1:606784160785:targetgroup/jenkins-dev/49d5199a83cf3941 --targets Id=
aws --profile a1  --region us-east-1  elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-1:606784160785:targetgroup/sciensa-dev/30895b398b8dd2bb --targets Id=
aws --profile a1  --region us-east-1  elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-1:606784160785:targetgroup/cppcms-dev/4c9decd880e3678e  --targets Id=
