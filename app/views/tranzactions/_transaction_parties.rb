<table class="offer" summary="Create/Update Offer">
	<tr>
		<td class="main">
			<%= "#{current_user().first_name} #{current_user().last_name} as " %>
			<%= f.select :originator_role, roles_for(@trans) %><br />
			<%= f.label :recipient %><br />
			<%= f.text_field :recipient %>
			<%= f.select :contact_method, contact_methods(@trans) %><br />
		</td>
	</tr>
</table>

<div class="party">
	<% return nil if party.class == AdminParty %>
	<% party.contact.user == current_user() %> 
