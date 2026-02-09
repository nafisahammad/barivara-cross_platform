// Central enums for Firestore documents.

enum UserRole { host, resident }

enum FlatStatus { vacant, occupied }

enum ApprovalStatus { pending, approved }

enum PaymentCategory { rent, electricity, water, gas, other }

enum PaymentStatus { pendingApproval, confirmed, due }

enum IssuePriority { low, medium, high, urgent }

enum IssueStatus { open, inProgress, resolved, closed }
