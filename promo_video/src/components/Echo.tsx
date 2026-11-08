import React from 'react';
import {AbsoluteFill, Freeze, useCurrentFrame} from 'remotion';

/**
 * Ghost copies of earlier frames composited *over* the current one, so the
 * echo reads even when the scene is fully opaque (Trail stacks them below).
 * This is the stepped zoom-trail look of the reference's camera whips.
 */
export const Echo: React.FC<{
  children: React.ReactNode;
  layers?: number;
  lag?: number;
  strength?: number;
}> = ({children, layers = 3, lag = 1, strength = 0.32}) => {
  const frame = useCurrentFrame();
  const ghosts = [];
  for (let k = layers; k >= 1; k--) {
    ghosts.push(
      <AbsoluteFill key={k} style={{opacity: strength * (1 - (k - 1) / layers)}}>
        <Freeze frame={frame - k * lag}>{children}</Freeze>
      </AbsoluteFill>,
    );
  }
  return (
    <AbsoluteFill>
      <AbsoluteFill>{children}</AbsoluteFill>
      {ghosts}
    </AbsoluteFill>
  );
};
