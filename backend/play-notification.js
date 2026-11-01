// Notifications only trigger authoritative Google revalidation. A refund may
// leave a subscription active; never revoke solely from an unverified payload.
export function subscriptionNotificationToken(notification, packageName) {
  if (notification?.packageName !== packageName) return null;
  const ordinary = notification.subscriptionNotification?.purchaseToken;
  const voided = notification.voidedPurchaseNotification;
  const token = ordinary ?? (voided?.productType === 1 ? voided.purchaseToken : null);
  return typeof token === 'string' && token.length >= 8 && token.length <= 4096 ? token : null;
}
