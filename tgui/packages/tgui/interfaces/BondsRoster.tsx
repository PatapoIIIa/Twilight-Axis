import { Box, Icon, NoticeBox, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Person = {
  name: string;
  job: string;
  self: number | boolean;
};

type Rank = {
  label: string;
  level: number;
  leader: number | boolean;
  people: Person[];
  vacant: string[];
};

type Block = {
  id: string;
  name: string;
  accent: string;
  icon: string;
  ranks: Rank[];
  total: number;
};

type Data = {
  own: Block | null;
  ally: Block | null;
  allyWarmth: number;
};

function RankRow(props: { rank: Rank; accent: string }) {
  const { rank, accent } = props;
  const leader = !!rank.leader;

  return (
    <Box
      mb={1}
      p={1}
      style={{
        borderLeft: `3px solid ${leader ? accent : '#3a3a3a'}`,
        background: leader ? '#1c1a14' : '#141414',
      }}
    >
      <Box bold color={leader ? accent : undefined}>
        {leader && <Icon name="chess-king" mr={1} />}
        {rank.label}
      </Box>
      {rank.people.map((person, index) => (
        <Box key={index} ml={1} mt={0.5}>
          <Box inline bold={!!person.self} color={person.self ? accent : undefined}>
            {person.name}
          </Box>
          <Box inline ml={1} opacity={0.55}>
            {person.job}
          </Box>
          {!!person.self && (
            <Box inline ml={1} color={accent} bold>
              — вы здесь
            </Box>
          )}
        </Box>
      ))}
      {rank.vacant.map((title, index) => (
        <Box key={`v${index}`} ml={1} mt={0.5} opacity={0.35} italic>
          <Icon name="user-slash" mr={1} />
          {title} — место свободно
        </Box>
      ))}
    </Box>
  );
}

function RosterBlock(props: { block: Block; subtitle?: string }) {
  const { block, subtitle } = props;

  return (
    <Section
      title={
        <Box inline color={block.accent} bold>
          <Icon name={block.icon} mr={1} />
          {block.name}
        </Box>
      }
    >
      {!!subtitle && (
        <Box opacity={0.6} mb={1}>
          {subtitle}
        </Box>
      )}
      {!block.ranks.length && (
        <Box opacity={0.6}>Об этой фракции ничего не известно.</Box>
      )}
      {block.ranks.map((rank, index) => (
        <RankRow key={index} rank={rank} accent={block.accent} />
      ))}
    </Section>
  );
}

export const BondsRoster = () => {
  const { data } = useBackend<Data>();
  const { own, ally, allyWarmth = 0 } = data;

  return (
    <Window title="Лист фракции" width={620} height={720}>
      <Window.Content scrollable style={{ backgroundImage: 'none' }}>
        {!own && <NoticeBox>Вы ни к кому не приписаны.</NoticeBox>}
        <Stack vertical fill>
          {!!own && (
            <Stack.Item>
              <RosterBlock
                block={own}
                subtitle={`На месте сейчас: ${own.total}`}
              />
            </Stack.Item>
          )}
          {!!ally && (
            <Stack.Item>
              <RosterBlock
                block={ally}
                subtitle={`Союзники · расположение ${allyWarmth}`}
              />
            </Stack.Item>
          )}
          {!!own && !ally && (
            <Stack.Item>
              <NoticeBox>
                Союзников, к кому стоило бы обратиться, сейчас нет.
              </NoticeBox>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
