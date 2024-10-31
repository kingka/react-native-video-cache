import { NativeModules } from 'react-native';

export default (url) => {
  if (!global.nativeCallSyncHook) {
    return url
  }
  return NativeModules.VideoCache.convert(url)
};
console.log('进的来吗')
export const convertAsync = NativeModules.VideoCache.convertAsync;
export const preload = NativeModules.VideoCache.preload;

