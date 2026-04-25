import { expect, test } from '@playwright/test';

test('app loads and reaches backend', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  // Backend status should resolve from 'unknown' to 'ok' or 'fail'
  await expect(page.locator('strong.ok, strong.fail')).toBeVisible({ timeout: 5000 });
});
