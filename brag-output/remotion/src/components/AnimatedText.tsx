import type {CSSProperties} from 'react';
import {useCurrentFrame, useVideoConfig} from 'remotion';
import {SPRING, enter} from '../lib/motion';

type Props = {
  text: string;
  /** Frames before the first word starts. */
  delay?: number;
  /** Frames between consecutive words (or characters). */
  stagger?: number;
  /** Reveal word by word (default) or character by character. */
  by?: 'word' | 'char';
  /** How long each piece takes to settle, in frames. Defaults to 0.7s. */
  duration?: number;
  /** Words styled differently, e.g. an accent gradient. Matched without punctuation. */
  highlight?: string[];
  highlightStyle?: CSSProperties;
  style?: CSSProperties;
};

/** A word without punctuation or case, so highlight={['code']} matches "code.". */
const bare = (word: string) => word.replace(/[^\p{L}\p{N}]/gu, '').toLowerCase();

/**
 * Masked text reveal: each word rises out of its own clipped line box while its blur
 * clears. Use `\n` to force a line break. Wrapping is otherwise natural, so the same
 * text reflows between landscape and portrait.
 */
export const AnimatedText: React.FC<Props> = ({
  text,
  delay = 0,
  stagger = 4,
  by = 'word',
  duration,
  highlight = [],
  highlightStyle,
  style,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const settle = duration ?? Math.round(fps * 0.7);
  const marks = new Set(highlight.map(bare));
  let index = 0;

  const piece = (content: string, key: string, extra?: CSSProperties) => {
    const p = enter(frame, fps, {
      delay: delay + index++ * stagger,
      config: SPRING.smooth,
      durationInFrames: settle,
    });
    return (
      <span
        key={key}
        style={{
          display: 'inline-block',
          overflow: 'hidden',
          verticalAlign: 'top',
          // Room for descenders and overhanging glyphs inside the clipping box.
          padding: '0.04em 0.04em 0.1em',
          margin: '-0.04em -0.04em -0.1em',
        }}
      >
        <span
          style={{
            display: 'inline-block',
            transform: `translateY(${(1 - p) * 105}%)`,
            filter: p < 0.999 ? `blur(${(1 - p) * 0.12}em)` : undefined,
            opacity: Math.min(1, p * 1.6),
            ...extra,
          }}
        >
          {content}
        </span>
      </span>
    );
  };

  return (
    <div style={style}>
      {text.split('\n').map((line, li) => (
        <div key={li}>
          {line.split(' ').map((word, wi) => {
            const isMarked = marks.has(bare(word));
            const extra = isMarked ? highlightStyle : undefined;
            const content =
              by === 'char' ? (
                <span style={{display: 'inline-block', whiteSpace: 'nowrap'}}>
                  {[...word].map((ch, ci) => piece(ch, `${ci}`, extra))}
                </span>
              ) : (
                piece(word, 'w', extra)
              );
            return (
              <span key={wi}>
                {wi > 0 ? ' ' : null}
                {content}
              </span>
            );
          })}
        </div>
      ))}
    </div>
  );
};
