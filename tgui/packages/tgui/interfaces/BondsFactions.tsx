import { useState } from 'react';
import { Box, Button, Dropdown, NoticeBox, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type FactionInfo = {
  name: string;
  accent: string;
};

type MapNode = {
  id: string;
  name: string;
  accent: string;
  own: number | boolean;
};

type MapEdge = {
  a: string;
  b: string;
  label: string;
  accent: string;
  warmth: number;
  weight: number;
  declared: number | boolean;
};

type HouseEntry = {
  name: string;
  label: string;
  labelAccent: string;
  intensity: string;
  incidents: number;
};

type StanceEntry = {
  name: string;
  accent: string;
  label: string;
  labelAccent: string;
  intensity: string;
};

type Data = {
  ownFaction: FactionInfo | null;
  map: { nodes: MapNode[]; edges: MapEdge[] };
  ownHouse: string | null;
  houses: HouseEntry[];
  ownClan: string | null;
  clans: StanceEntry[];
};

const SIZE = 560;
const CENTER = SIZE / 2;
const RING = 215;
const NODE_R = 34;

export const BondsFactions = () => {
  const { data } = useBackend<Data>();
  const {
    ownFaction,
    map = { nodes: [], edges: [] },
    ownHouse,
    houses = [],
    ownClan,
    clans = [],
  } = data;

  const nodes = map.nodes || [];
  const edges = map.edges || [];

  const [hidden, setHidden] = useState<Record<string, boolean>>({});
  const [pickA, setPickA] = useState<string>('');
  const [pickB, setPickB] = useState<string>('');
  const [showNeutral, setShowNeutral] = useState(false);

  const edgeKey = (edge: MapEdge) => `${edge.a}|${edge.b}`;
  const isHighlighted = (edge: MapEdge) =>
    !!pickA &&
    !!pickB &&
    ((edge.a === pickA && edge.b === pickB) ||
      (edge.a === pickB && edge.b === pickA));
  const nodeNames = nodes.map((node) => node.name);
  const idByName: Record<string, string> = {};
  nodes.forEach((node) => {
    idByName[node.name] = node.id;
  });

  // Node positions are derived once from the ring order and shared with the edges.
  const placed: Record<string, { x: number; y: number; node: MapNode }> = {};
  nodes.forEach((node, index) => {
    const angle = (index / Math.max(nodes.length, 1)) * Math.PI * 2 - Math.PI / 2;
    placed[node.id] = {
      x: CENTER + Math.cos(angle) * RING,
      y: CENTER + Math.sin(angle) * RING,
      node,
    };
  });

  return (
    <Window title="Карта сил" width={640} height={780}>
      <Window.Content scrollable style={{ backgroundImage: 'none' }}>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Между фракциями">
              {!edges.length && (
                <Box opacity={0.6}>
                  Между фракциями пока ничего не произошло.
                </Box>
              )}
              <svg
                viewBox={`0 0 ${SIZE} ${SIZE}`}
                style={{ width: '100%', height: 'auto' }}
              >
                {edges.map((edge, index) => {
                  const from = placed[edge.a];
                  const to = placed[edge.b];
                  if (!from || !to) return null;
                  const key = edgeKey(edge);
                  const declared = !!edge.declared;
                  if (!declared && !showNeutral) return null;
                  const highlighted = isHighlighted(edge);
                  const faded = hidden[key];
                  const midX = (from.x + to.x) / 2;
                  const midY = (from.y + to.y) / 2;
                  const thickness = highlighted
                    ? 5
                    : 1 + Math.min(6, edge.weight / 15);
                  const opacity = faded ? 0.07 : highlighted ? 1 : declared ? 0.65 : 0.18;
                  return (
                    <g
                      key={index}
                      onClick={() =>
                        setHidden({ ...hidden, [key]: !hidden[key] })
                      }
                      style={{ cursor: 'pointer' }}
                    >
                      {!!highlighted && (
                        <line
                          x1={from.x}
                          y1={from.y}
                          x2={to.x}
                          y2={to.y}
                          stroke="#ffffff"
                          strokeWidth={thickness + 4}
                          opacity={0.25}
                        />
                      )}
                      <line
                        x1={from.x}
                        y1={from.y}
                        x2={to.x}
                        y2={to.y}
                        stroke={edge.accent}
                        strokeWidth={thickness}
                        opacity={opacity}
                      />
                      {!faded && (declared || highlighted) && (
                        <text
                          x={midX}
                          y={midY - 3}
                          textAnchor="middle"
                          fill={edge.accent}
                          fontSize={highlighted ? '12' : '10'}
                          fontWeight={highlighted ? 'bold' : 'normal'}
                          opacity={opacity}
                          style={{ pointerEvents: 'none' }}
                        >
                          {edge.label}
                        </text>
                      )}
                    </g>
                  );
                })}
                {nodes.map((node) => {
                  const spot = placed[node.id];
                  if (!spot) return null;
                  return (
                    <g key={node.id}>
                      <circle
                        cx={spot.x}
                        cy={spot.y}
                        r={NODE_R}
                        fill={node.own ? '#2a2418' : '#1b1b1b'}
                        stroke={node.accent}
                        strokeWidth={node.own ? 3 : 2}
                      />
                      <text
                        x={spot.x}
                        y={spot.y + 3}
                        textAnchor="middle"
                        fill="#e8e8e8"
                        fontSize="9"
                      >
                        {node.name.length > 13
                          ? `${node.name.slice(0, 12)}…`
                          : node.name}
                      </text>
                    </g>
                  );
                })}
              </svg>
              <Stack mt={1} align="center" wrap>
                <Stack.Item>
                  <Dropdown
                    options={nodeNames}
                    selected={pickA ? nodes.find((n) => n.id === pickA)?.name : ''}
                    placeholder="фракция"
                    width="10rem"
                    onSelected={(name) => setPickA(idByName[name] || '')}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Dropdown
                    options={nodeNames}
                    selected={pickB ? nodes.find((n) => n.id === pickB)?.name : ''}
                    placeholder="и фракция"
                    width="10rem"
                    onSelected={(name) => setPickB(idByName[name] || '')}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="eraser"
                    onClick={() => {
                      setPickA('');
                      setPickB('');
                    }}
                  >
                    сбросить
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button.Checkbox
                    checked={showNeutral}
                    onClick={() => setShowNeutral(!showNeutral)}
                  >
                    все пары
                  </Button.Checkbox>
                </Stack.Item>
                <Stack.Item>
                  <Button icon="eye" onClick={() => setHidden({})}>
                    вернуть скрытые
                  </Button>
                </Stack.Item>
              </Stack>
              <Box mt={0.5} opacity={0.5}>
                Клик по линии убирает её с карты.
              </Box>
              {!!ownFaction && (
                <Box mt={1} opacity={0.7}>
                  Обведена ваша фракция:{' '}
                  <Box inline bold color={ownFaction.accent}>
                    {ownFaction.name}
                  </Box>
                </Box>
              )}
            </Section>
          </Stack.Item>

          {!!ownClan && (
            <Stack.Item>
              <Section title={`Клан: ${ownClan}`}>
                <Stack vertical>
                  {clans.map((clan, index) => (
                    <Stack.Item key={`c${index}`}>
                      <Box inline bold color={clan.accent}>
                        {clan.name}
                      </Box>
                      <Box inline ml={1} bold color={clan.labelAccent}>
                        {clan.label}
                      </Box>
                      <Box opacity={0.6}>{clan.intensity}</Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {!!ownHouse && (
            <Stack.Item>
              <Section title={`Дом ${ownHouse}`}>
                {!houses.length && (
                  <Box opacity={0.6}>
                    С другими домами у вас пока ничего не случалось.
                  </Box>
                )}
                <Stack vertical>
                  {houses.map((house, index) => (
                    <Stack.Item key={`h${index}`}>
                      <Box inline bold>
                        {house.name}
                      </Box>
                      <Box inline ml={1} bold color={house.labelAccent}>
                        {house.label}
                      </Box>
                      <Box opacity={0.6}>
                        {house.intensity} · случаев: {house.incidents}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {!ownFaction && !ownHouse && !ownClan && !edges.length && (
            <Stack.Item>
              <NoticeBox>Вам пока не о чем судить.</NoticeBox>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
