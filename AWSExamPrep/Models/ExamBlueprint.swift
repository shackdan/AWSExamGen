import Foundation

struct BlueprintDomain: Identifiable {
    let id = UUID()
    let name: String
    let weight: Double
    let keywords: [String]
}

struct ExamBlueprint {
    let certType: String
    let domains: [BlueprintDomain]

    func bestMatchingDomain(for text: String) -> BlueprintDomain? {
        let lower = text.lowercased()
        return domains.max {
            $0.keywords.filter { lower.contains($0.lowercased()) }.count <
            $1.keywords.filter { lower.contains($0.lowercased()) }.count
        }
    }
}

let examBlueprints: [String: ExamBlueprint] = [
    "SAA-C03": ExamBlueprint(certType: "SAA-C03", domains: [
        BlueprintDomain(name: "Design Secure Architectures", weight: 30,
            keywords: ["IAM", "security group", "KMS", "ACM", "WAF", "Shield", "policy", "encryption",
                       "authentication", "authorization", "secrets manager", "cognito"]),
        BlueprintDomain(name: "Design Resilient Architectures", weight: 26,
            keywords: ["availability", "fault tolerant", "multi-AZ", "replication", "disaster recovery",
                       "backup", "RTO", "RPO", "failover", "route 53", "health check"]),
        BlueprintDomain(name: "Design High-Performing Architectures", weight: 24,
            keywords: ["performance", "cache", "elasticache", "cloudfront", "CDN", "auto scaling",
                       "throughput", "latency", "read replica", "global accelerator"]),
        BlueprintDomain(name: "Design Cost-Optimized Architectures", weight: 20,
            keywords: ["cost", "pricing", "reserved", "spot instance", "savings plan", "optimize",
                       "budget", "right-sizing", "lifecycle", "S3 intelligent-tiering"])
    ]),
    "DVA-C02": ExamBlueprint(certType: "DVA-C02", domains: [
        BlueprintDomain(name: "Development with AWS Services", weight: 32,
            keywords: ["lambda", "API gateway", "DynamoDB", "S3", "SQS", "SNS", "SDK", "CLI",
                       "CodeBuild", "CodeDeploy", "CodePipeline", "X-Ray"]),
        BlueprintDomain(name: "Security", weight: 26,
            keywords: ["IAM", "Cognito", "STS", "KMS", "secrets manager", "encryption",
                       "token", "authentication", "authorization", "policy"]),
        BlueprintDomain(name: "Deployment", weight: 24,
            keywords: ["CodeDeploy", "CodePipeline", "Elastic Beanstalk", "ECS", "CloudFormation",
                       "SAM", "deployment", "blue/green", "canary", "rolling"]),
        BlueprintDomain(name: "Troubleshooting and Optimization", weight: 18,
            keywords: ["X-Ray", "CloudWatch", "logging", "debugging", "performance", "optimize",
                       "latency", "error", "throttle", "retry", "exponential backoff"])
    ]),
    "SOA-C02": ExamBlueprint(certType: "SOA-C02", domains: [
        BlueprintDomain(name: "Monitoring, Logging, and Remediation", weight: 20,
            keywords: ["CloudWatch", "CloudTrail", "Config", "alarm", "metrics", "logs",
                       "EventBridge", "SSM", "OpsCenter", "remediation"]),
        BlueprintDomain(name: "Reliability and Business Continuity", weight: 16,
            keywords: ["backup", "disaster recovery", "multi-AZ", "RTO", "RPO", "failover",
                       "replication", "fault tolerance", "health check"]),
        BlueprintDomain(name: "Deployment, Provisioning, and Automation", weight: 18,
            keywords: ["CloudFormation", "Systems Manager", "Elastic Beanstalk", "AMI",
                       "automation", "patch", "provisioning", "deployment"]),
        BlueprintDomain(name: "Security and Compliance", weight: 16,
            keywords: ["IAM", "security group", "KMS", "ACM", "WAF", "compliance", "policy",
                       "encryption", "inspector", "trusted advisor"]),
        BlueprintDomain(name: "Networking and Content Delivery", weight: 18,
            keywords: ["VPC", "subnet", "route table", "NAT", "CloudFront", "Route 53",
                       "load balancer", "Direct Connect", "VPN", "transit gateway"]),
        BlueprintDomain(name: "Cost and Performance Optimization", weight: 12,
            keywords: ["cost", "reserved", "spot", "savings plan", "right-sizing",
                       "performance", "auto scaling", "budget", "cost explorer"])
    ]),
    "SAP-C02": ExamBlueprint(certType: "SAP-C02", domains: [
        BlueprintDomain(name: "Design Solutions for Organizational Complexity", weight: 26,
            keywords: ["organizations", "control tower", "landing zone", "multi-account",
                       "SCP", "governance", "cross-account", "federation"]),
        BlueprintDomain(name: "Design for New Solutions", weight: 29,
            keywords: ["architecture", "microservices", "event-driven", "serverless",
                       "containers", "hybrid", "migration", "design pattern"]),
        BlueprintDomain(name: "Continuous Improvement for Existing Solutions", weight: 25,
            keywords: ["well-architected", "performance", "cost", "reliability",
                       "security", "operational excellence", "sustainability", "review"]),
        BlueprintDomain(name: "Accelerate Workload Migration and Modernization", weight: 20,
            keywords: ["migration", "DMS", "SMS", "MGN", "refactor", "rehost", "replatform",
                       "modernize", "database migration", "6 R's"])
    ]),
    "DOP-C02": ExamBlueprint(certType: "DOP-C02", domains: [
        BlueprintDomain(name: "SDLC Automation", weight: 22,
            keywords: ["CodeCommit", "CodeBuild", "CodeDeploy", "CodePipeline", "CI/CD",
                       "pipeline", "artifact", "testing", "code review"]),
        BlueprintDomain(name: "Configuration Management and IaC", weight: 17,
            keywords: ["CloudFormation", "CDK", "Terraform", "Systems Manager", "OpsWorks",
                       "configuration", "drift", "stack", "parameter store"]),
        BlueprintDomain(name: "Resilient Cloud Solutions", weight: 15,
            keywords: ["availability", "fault tolerant", "auto scaling", "multi-region",
                       "backup", "disaster recovery", "health check", "failover"]),
        BlueprintDomain(name: "Monitoring and Logging", weight: 15,
            keywords: ["CloudWatch", "X-Ray", "CloudTrail", "Firehose", "Kinesis",
                       "dashboard", "alarm", "metrics", "logs", "tracing"]),
        BlueprintDomain(name: "Incident and Event Response", weight: 14,
            keywords: ["EventBridge", "SNS", "Lambda", "incident", "runbook", "OpsCenter",
                       "alerting", "on-call", "SSM Automation"]),
        BlueprintDomain(name: "Security and Compliance", weight: 17,
            keywords: ["IAM", "Config", "Security Hub", "Inspector", "GuardDuty",
                       "compliance", "policy", "encryption", "secrets"])
    ]),
    "CLF-C02": ExamBlueprint(certType: "CLF-C02", domains: [
        BlueprintDomain(name: "Cloud Concepts", weight: 24,
            keywords: ["cloud computing", "benefits", "elasticity", "scalability",
                       "global infrastructure", "availability zone", "region", "shared responsibility"]),
        BlueprintDomain(name: "Security and Compliance", weight: 30,
            keywords: ["IAM", "security", "compliance", "shared responsibility", "WAF",
                       "Shield", "encryption", "artifact", "trusted advisor"]),
        BlueprintDomain(name: "Cloud Technology and Services", weight: 34,
            keywords: ["EC2", "S3", "RDS", "Lambda", "VPC", "CloudFront", "Route 53",
                       "ECS", "SNS", "SQS", "DynamoDB", "Elastic Beanstalk"]),
        BlueprintDomain(name: "Billing, Pricing, and Support", weight: 12,
            keywords: ["billing", "pricing", "cost explorer", "budget", "free tier",
                       "support plan", "reserved", "savings plan", "total cost of ownership"])
    ]),
    "ANS-C01": ExamBlueprint(certType: "ANS-C01", domains: [
        BlueprintDomain(name: "Network Design", weight: 30,
            keywords: ["VPC", "subnet", "CIDR", "routing", "transit gateway", "peering",
                       "Direct Connect", "VPN", "hybrid", "architecture"]),
        BlueprintDomain(name: "Network Implementation", weight: 26,
            keywords: ["NAT", "internet gateway", "route table", "security group", "NACL",
                       "load balancer", "DNS", "Route 53", "CloudFront"]),
        BlueprintDomain(name: "Network Management and Operations", weight: 20,
            keywords: ["monitoring", "CloudWatch", "VPC flow logs", "traffic mirroring",
                       "network manager", "health check", "logging"]),
        BlueprintDomain(name: "Network Security, Compliance, and Governance", weight: 24,
            keywords: ["WAF", "Shield", "firewall", "Network Firewall", "security group",
                       "NACL", "compliance", "encryption", "private link"])
    ]),
    "MLS-C01": ExamBlueprint(certType: "MLS-C01", domains: [
        BlueprintDomain(name: "Data Engineering", weight: 20,
            keywords: ["data pipeline", "Kinesis", "Glue", "S3", "Lake Formation",
                       "ingestion", "ETL", "data lake", "batch", "streaming"]),
        BlueprintDomain(name: "Exploratory Data Analysis", weight: 24,
            keywords: ["SageMaker", "notebook", "data analysis", "visualization",
                       "feature engineering", "EDA", "Athena", "QuickSight"]),
        BlueprintDomain(name: "Modeling", weight: 36,
            keywords: ["SageMaker", "training", "algorithm", "hyperparameter", "neural network",
                       "deep learning", "XGBoost", "overfitting", "validation", "model"]),
        BlueprintDomain(name: "Machine Learning Implementation and Operations", weight: 20,
            keywords: ["deployment", "endpoint", "inference", "A/B testing", "monitoring",
                       "MLOps", "pipeline", "batch transform", "model registry"])
    ])
]
