import { describe, expect, it } from 'vitest';

import {
  classifyApkAssetName,
  collectApkAssets,
  normalizeReleaseVersion,
  recommendPrimaryAsset,
} from './apk-release';

describe('classifyApkAssetName', () => {
  it('classifies arm64-v8a APK assets', () => {
    expect(classifyApkAssetName('ledgerly-v1.0.0-arm64-v8a.apk')).toBe(
      'arm64-v8a',
    );
  });

  it('classifies armeabi-v7a APK assets', () => {
    expect(classifyApkAssetName('ledgerly-v1.0.0-armeabi-v7a.apk')).toBe(
      'armeabi-v7a',
    );
  });

  it('classifies x86_64 APK assets', () => {
    expect(classifyApkAssetName('ledgerly-v1.0.0-x86_64.apk')).toBe('x86_64');
  });
});

describe('collectApkAssets', () => {
  it('ignores non-APK assets, checksums, and archives', () => {
    expect(
      collectApkAssets([
        { name: 'ledgerly-v1.0.0-arm64-v8a.apk', browser_download_url: 'https://example.com/arm64.apk' },
        { name: 'ledgerly-v1.0.0-arm64-v8a.apk.sha256', browser_download_url: 'https://example.com/arm64.apk.sha256' },
        { name: 'ledgerly-v1.0.0.zip', browser_download_url: 'https://example.com/release.zip' },
        { name: 'release-notes.txt', browser_download_url: 'https://example.com/release-notes.txt' },
        { name: 'ledgerly-v1.0.0-universal.apk.tar.gz', browser_download_url: 'https://example.com/universal.apk.tar.gz' },
      ]),
    ).toEqual([
      {
        abi: 'arm64-v8a',
        name: 'ledgerly-v1.0.0-arm64-v8a.apk',
        url: 'https://example.com/arm64.apk',
      },
    ]);
  });

  it('handles partial lists with one or two APKs', () => {
    expect(
      collectApkAssets([
        { name: 'ledgerly-v1.0.0-armeabi-v7a.apk', browser_download_url: 'https://example.com/armeabi.apk' },
      ]),
    ).toEqual([
      {
        abi: 'armeabi-v7a',
        name: 'ledgerly-v1.0.0-armeabi-v7a.apk',
        url: 'https://example.com/armeabi.apk',
      },
    ]);

    expect(
      collectApkAssets([
        { name: 'ledgerly-v1.0.0-x86_64.apk', browser_download_url: 'https://example.com/x86_64.apk' },
        { name: 'ledgerly-v1.0.0-arm64-v8a.apk', browser_download_url: 'https://example.com/arm64.apk' },
      ]),
    ).toEqual([
      {
        abi: 'x86_64',
        name: 'ledgerly-v1.0.0-x86_64.apk',
        url: 'https://example.com/x86_64.apk',
      },
      {
        abi: 'arm64-v8a',
        name: 'ledgerly-v1.0.0-arm64-v8a.apk',
        url: 'https://example.com/arm64.apk',
      },
    ]);
  });
});

describe('recommendPrimaryAsset', () => {
  it('prefers arm64-v8a when available', () => {
    expect(
      recommendPrimaryAsset([
        {
          abi: 'x86_64',
          name: 'ledgerly-v1.0.0-x86_64.apk',
          url: 'https://example.com/x86_64.apk',
        },
        {
          abi: 'arm64-v8a',
          name: 'ledgerly-v1.0.0-arm64-v8a.apk',
          url: 'https://example.com/arm64.apk',
        },
      ]),
    ).toEqual({
      abi: 'arm64-v8a',
      name: 'ledgerly-v1.0.0-arm64-v8a.apk',
      url: 'https://example.com/arm64.apk',
    });
  });

  it('falls back to armeabi-v7a, then x86_64', () => {
    expect(
      recommendPrimaryAsset([
        {
          abi: 'x86_64',
          name: 'ledgerly-v1.0.0-x86_64.apk',
          url: 'https://example.com/x86_64.apk',
        },
        {
          abi: 'armeabi-v7a',
          name: 'ledgerly-v1.0.0-armeabi-v7a.apk',
          url: 'https://example.com/armeabi.apk',
        },
      ]),
    ).toEqual({
      abi: 'armeabi-v7a',
      name: 'ledgerly-v1.0.0-armeabi-v7a.apk',
      url: 'https://example.com/armeabi.apk',
    });

    expect(
      recommendPrimaryAsset([
        {
          abi: 'x86_64',
          name: 'ledgerly-v1.0.0-x86_64.apk',
          url: 'https://example.com/x86_64.apk',
        },
      ]),
    ).toEqual({
      abi: 'x86_64',
      name: 'ledgerly-v1.0.0-x86_64.apk',
      url: 'https://example.com/x86_64.apk',
    });
  });

  it('returns null when no classified assets exist', () => {
    expect(recommendPrimaryAsset([])).toBeNull();
  });
});

describe('normalizeReleaseVersion', () => {
  it('keeps version tags that already start with v', () => {
    expect(normalizeReleaseVersion('v0.1.1')).toBe('v0.1.1');
  });

  it('adds v when the release tag omits it', () => {
    expect(normalizeReleaseVersion('0.1.1')).toBe('v0.1.1');
  });

  it('returns null for empty tags', () => {
    expect(normalizeReleaseVersion('')).toBeNull();
    expect(normalizeReleaseVersion(undefined)).toBeNull();
  });
});
