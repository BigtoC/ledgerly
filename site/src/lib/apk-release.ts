export type ApkAbi = 'arm64-v8a' | 'armeabi-v7a' | 'x86_64';

export interface ReleaseAsset {
  name: string;
  browser_download_url: string;
}

export interface ClassifiedApkAsset {
  name: string;
  url: string;
  abi: ApkAbi;
}

const ABI_PRIORITY: ApkAbi[] = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];

export function classifyApkAssetName(name: string): ApkAbi | null {
  const normalizedName = name.toLowerCase();

  if (!normalizedName.endsWith('.apk')) {
    return null;
  }

  for (const abi of ABI_PRIORITY) {
    if (normalizedName.includes(`-${abi}.apk`)) {
      return abi;
    }
  }

  return null;
}

export function collectApkAssets(assets: ReleaseAsset[]): ClassifiedApkAsset[] {
  return assets.flatMap((asset) => {
    const abi = classifyApkAssetName(asset.name);

    if (!abi) {
      return [];
    }

    return [{
      name: asset.name,
      url: asset.browser_download_url,
      abi,
    }];
  });
}

export function recommendPrimaryAsset(
  assets: ClassifiedApkAsset[],
): ClassifiedApkAsset | null {
  for (const abi of ABI_PRIORITY) {
    const asset = assets.find((candidate) => candidate.abi === abi);

    if (asset) {
      return asset;
    }
  }

  return null;
}
